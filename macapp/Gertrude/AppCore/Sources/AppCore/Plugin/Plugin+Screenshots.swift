import CoreGraphics
import Foundation

class ScreenshotsPlugin: Plugin {
  private var store: AppStore
  private var timer: Timer?
  private var state: MonitoringState { store.state.monitoring }

  init(store: AppStore) {
    self.store = store
    configure()
  }

  func configure() {
    cleanup()
    guard state.screenshotsEnabled else {
      return
    }

    let freq = Double(max(10, state.screenshotFrequency))
    let size = max(500, state.screenshotSize)

    timer = Timer.repeating(every: freq) { [weak self] _ in
      if self?.store.state.accountStatus != .inactive {
        DispatchQueue.global(qos: .background).async {
          Screenshot.shared.take(width: size)
        }
      }
    }

    log(.plugin("Screenshots", .level(.info, "started screenshot monitoring", [
      "meta.primary": .string("freq=\(freq), size=\(size)"),
    ])))
  }

  func cleanup() {
    if timer != nil {
      log(.plugin("Screenshots", .info("stopped screenshot monitoring")))
    }
    timer?.invalidate()
    timer = nil
  }

  func respond(to event: AppEvent) {
    switch event {
    case .screenshotsStateChanged:
      configure()
    default:
      break
    }
  }

  func onTerminate() {
    cleanup()
  }

  static var permissionGranted: Bool {
    CGPreflightScreenCaptureAccess()
  }
}
