import LibController
import NetworkExtension
import os.log

class FilterControlProvider: NEFilterControlProvider {
  let proxy = ControllerProxy()

  override init() {
    super.init()
    self.proxy.notifyRulesChanged = { [weak self] in
      self?.notifyRulesChanged()
    }

    #if DEBUG
      self.proxy.startHeartbeat(initialDelay: .seconds(30), interval: .minutes(2))
    #else
      self.proxy.startHeartbeat(initialDelay: .seconds(60), interval: .minutes(60))
    #endif

    os_log("[G•] CONTROLLER init")
  }

  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    os_log("[G•] CONTROLLER start")
    self.proxy.startFilter()
    completionHandler(nil)
  }

  override func stopFilter(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    self.proxy.stopFilter(reason: reason)
    os_log("[G•] CONTROLLER stop reason: %{public}s", String(describing: reason))
    completionHandler()
  }

  override func handleNewFlow(
    _ flow: NEFilterFlow,
    completionHandler: @escaping (NEFilterControlVerdict) -> Void
  ) {
    self.proxy.handleNewFlow(flow)
    completionHandler(.allow(withUpdateRules: false))
  }
}
