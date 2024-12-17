import AppKit
import Gertie

public extension NSRunningApplication {
  var name: String? {
    self.localizedName ?? self.bundleName
  }

  var bundleName: String? {
    guard let bundleURL = self.bundleURL else { return nil }
    guard let infoPlist = NSDictionary(
      contentsOf: bundleURL
        .appendingPathComponent("Contents/Info.plist")
    ) else { return nil }
    return infoPlist["CFBundleName"] as? String
  }

  var runningApp: RunningApp? {
    self.bundleIdentifier.map {
      RunningApp(
        pid: self.processIdentifier,
        bundleId: $0,
        bundleName: self.bundleName,
        localizedName: self.localizedName,
        launchable: self.activationPolicy != .prohibited
      )
    }
  }
}

public extension RunningApp {
  init?(app: NSRunningApplication) {
    guard let bundleId = app.bundleIdentifier else { return nil }
    self.init(
      pid: app.processIdentifier,
      bundleId: bundleId,
      bundleName: app.bundleName,
      localizedName: app.localizedName,
      launchable: app.activationPolicy != .prohibited
    )
  }

  init?(pid: pid_t) {
    guard let app = NSRunningApplication(processIdentifier: pid) else { return nil }
    self.init(app: app)
  }

  var nsRunningApplication: NSRunningApplication? {
    NSRunningApplication(processIdentifier: self.pid)
  }
}
