import Foundation
import NetworkExtension
import Gertie
import SharedCore
import SystemExtensions

class FilterController {
  var statusChangeSubscriber: ((FilterStatus) -> Void)?
  var observer: Any?
  var requestDelegate: FilterActivationRequestDelegate?
  var connection: NSXPCConnection?
  private var _status: FilterStatus = .unknown
  private var _filterReceiver: ReceiveAppMessageInterface?
  static let shared = FilterController()

  var filterManager: NEFilterManager {
    NEFilterManager.shared()
  }

  var status: FilterStatus {
    get { _status }
    set {
      _status = newValue
      statusChangeSubscriber?(newValue)
    }
  }

  func load() {
    log(.filterController(.methodInvoked(#function)))

    loadFilterConfiguration { success in
      guard success else {
        log(.filterController(.error("\(#function) loadFilterConfiguration callback fail", nil)))
        self.status = .error
        return
      }

      log(.filterController(.info("loadFilterConfiguration callback success")))
      self.updateStatus()

      guard self.observer == nil else { return }

      self.observer = NotificationCenter.default.addObserver(
        forName: .NEFilterConfigurationDidChange,
        object: NEFilterManager.shared(),
        queue: .main
      ) { [weak self] _ in
        self?.updateStatus()
      }
    }
  }

  func unload() {
    log(.filterController(.methodInvoked(#function)))
    guard let observer = observer else { return }
    NotificationCenter.default.removeObserver(
      observer,
      name: .NEFilterConfigurationDidChange,
      object: NEFilterManager.shared()
    )
  }

  func start() {
    log(.filterController(.methodInvoked(#function)))
    status = .unknown
    guard !NEFilterManager.shared().isEnabled else {
      // one time i got in a weird state where the filter was NOT installed or running
      // and was showing as enabled. to get out, i had to call
      // NEFilterManager.shared().removeFromPreferences()
      // if that seems to happen often, maybe I should return a Bool from registerWithProvider()
      // and remove the prefs if I get a `false` ¯\_(ツ)_/¯
      log(.filterController(.info("filter enabled, starting registration")))
      registerWithProvider()
      return
    }

    log(.filterController(.notice("filter not enabled, requesting activation")))
    requestActivation()
  }

  func remove() {
    log(.filterController(.methodInvoked(#function)))
    filterManager.removeFromPreferences { error in
      if let error = error {
        log(.filterController(.error("error removing filter", error)))
      } else {
        log(.filterController(.info("removed filter")))
      }
    }
  }

  func requestActivation() {
    log(.filterController(.methodInvoked(#function)))

    guard let identifier = FilterBundle.identifier else {
      log(.filterController(.error("failed to get bundle identifier", nil)))
      status = .error
      return
    }

    log(.filterController(.notice("submitting extension activation request")))
    let activationRequest = OSSystemExtensionRequest.activationRequest(
      forExtensionWithIdentifier: identifier,
      queue: .main
    )
    let delegate = FilterActivationRequestDelegate(filterController: self)
    requestDelegate = delegate
    activationRequest.delegate = requestDelegate
    OSSystemExtensionManager.shared.submitRequest(activationRequest)
  }

  func replace() {
    log(.filterController(.notice("FilterController.replace() called, replacing...")))

    destroyConnection()
    requestActivation()

    // retry re-establishing connection a couple times in case the xpc comm breaks
    afterDelayOf(seconds: 5) { [weak self] in
      log(.filterController(.notice("replace retry xpc register (5 seconds)")))
      self?.registerWithProvider()
    }
    afterDelayOf(seconds: 15) { [weak self] in
      log(.filterController(.notice("replace retry xpc register (15 seconds)")))
      self?.registerWithProvider()
    }
  }

  func stop() {
    log(.filterController(.methodInvoked(#function)))
    status = .unknown

    guard filterManager.isEnabled else {
      log(.filterController(.info("\(#function) early bail: filter not enabled")))
      status = .installedButNotRunning
      return
    }

    loadFilterConfiguration { success in
      guard success else {
        log(.filterController(.error("\(#function) loadFilterConfiguration callback fail", nil)))
        self.status = .installedButNotRunning
        return
      }

      self.filterManager.isEnabled = false
      self.filterManager.saveToPreferences { saveError in
        DispatchQueue.main.async {
          if let err = saveError {
            log(.filterController(.error("error saving filter disable", err)))
            self.status = .installedAndRunning
            return
          }

          log(.filterController(.info("saved filter disable")))
          self.status = .installedButNotRunning
          self.destroyConnection()
        }
      }
    }
  }

  func enableFilterConfiguration() {
    log(.filterController(.methodInvoked(#function)))
    let filterManager = NEFilterManager.shared()

    guard !filterManager.isEnabled else {
      log(.filterController(.info("filter already enabled, registering")))
      registerWithProvider()
      return
    }

    loadFilterConfiguration { success in
      guard success else {
        log(.filterController(.error("\(#function) loadFilterConfiguration callback fail", nil)))
        self.status = .error
        return
      }

      log(.filterController(.info("\(#function) loadFilterConfiguration callback success")))

      if filterManager.providerConfiguration == nil {
        log(.filterController(.info("creating filter provider configuration")))
        let providerConfiguration = NEFilterProviderConfiguration()
        providerConfiguration.filterSockets = true
        providerConfiguration.filterPackets = false
        filterManager.providerConfiguration = providerConfiguration
        if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
          filterManager.localizedDescription = appName
        }
      } else {
        log(.filterController(.info("filter provider configuration already exists")))
      }

      filterManager.isEnabled = true

      filterManager.saveToPreferences { saveError in
        DispatchQueue.main.async {
          if let error = saveError {
            log(.filterController(.error("failed to save filter config", error)))
            self.status = .error
            return
          }

          log(.filterController(.info("saved filter config")))
          self.registerWithProvider()
        }
      }
    }
  }

  private func loadFilterConfiguration(completionHandler: @escaping (Bool) -> Void) {
    log(.filterController(.methodInvoked(#function)))

    filterManager.loadFromPreferences { loadError in
      DispatchQueue.main.async {
        var success = true
        if let error = loadError {
          log(.filterController(.error("error loading filter config", error)))
          success = false
        } else {
          log(.filterController(.info("successfully loaded filter config")))
        }
        completionHandler(success)
      }
    }
  }

  private func updateStatus() {
    log(.filterController(.methodInvoked(#function)))
    if filterManager.isEnabled {
      log(.filterController(.info("filter is enabled, registering")))
      registerWithProvider()
    } else {
      status = .installedButNotRunning
      log(.filterController(.info("filter is not enabled")))
    }
  }

  // "registering" serves 2 purposes:
  // 1) it lets us definitively know whether the filter is running
  //    if it calls our completion handler with `true`
  // 2) it initiates/opens the XPC communication, which only the App can do
  private func registerWithProvider() {
    log(.filterController(.methodInvoked(#function)))

    let registrationCompletionHandler = { (success: Bool) in
      DispatchQueue.main.async {
        if success {
          log(.filterController(.info("xpc registration handler called: success")))
          FilterController.shared.status = .installedAndRunning
        } else {
          log(.filterController(.error("xpc registration handler called: failure", nil)))
          FilterController.shared.status = .installedButNotRunning
        }
        FilterController.shared.status = success ? .installedAndRunning : .installedButNotRunning
      }
    }

    guard connection == nil else {
      log(.filterController(.info("app already registered")))
      registrationCompletionHandler(true)
      return
    }

    createXpcConnection()

    guard let receiver = filterReceiver else {
      log(.filterController(.warn("failed to get a filter receiver remote proxy object")))
      registrationCompletionHandler(false)
      return
    }

    log(.filterController(.info("calling register on filter receiver proxy")))
    receiver.register(registrationCompletionHandler)
  }

  private func createXpcConnection() {
    log(.filterController(.methodInvoked(#function)))
    guard connection == nil else {
      log(.filterController(.info("early return from \(#function), connection exists")))
      return
    }

    log(.filterController(.info("creating new xpc connection from app")))
    let conn = NSXPCConnection(machServiceName: SharedConstants.MACH_SERVICE_NAME, options: [])
    conn.exportedInterface = NSXPCInterface(with: ReceiveFilterMessageInterface.self)
    conn.exportedObject = ReceiveFilterMessage() // TODO: weak var things?
    conn.remoteObjectInterface = NSXPCInterface(with: ReceiveAppMessageInterface.self)
    connection = conn
    conn.resume()
  }

  var filterReceiver: ReceiveAppMessageInterface? {
    if let cachedReceiver = _filterReceiver {
      return cachedReceiver
    }

    guard let conn = connection else {
      log(.filterController(.warn("filterReceiver early bail: no connection")))
      return nil
    }

    let proxy = conn.remoteObjectProxyWithErrorHandler { error in
      log(.filterController(.error("error getting filter receiver remote object", error)))
      self.destroyConnection()
    }

    // if we destroyed the connection in the error handler above, bail
    guard connection != nil else {
      log(.filterController(.warn("filterReceiver early bail: connection destroyed")))
      return nil
    }

    guard let receiver = proxy as? ReceiveAppMessageInterface else {
      log(.filterController(.error("failed to create remote proxy object", nil)))
      return nil
    }

    log(.filterController(.info("created remote proxy object, cached for reuse")))
    _filterReceiver = receiver
    return receiver
  }

  private func destroyConnection() {
    log(.filterController(.methodInvoked(#function)))
    connection?.invalidate()
    connection = nil
    _filterReceiver = nil
  }
}
