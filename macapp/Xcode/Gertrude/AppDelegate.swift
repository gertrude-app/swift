import App
import AppKit
import Cocoa
import LiveApiClient
import LiveAppClient
import LiveFilterExtensionClient
import LiveFilterXPCClient
import LiveUpdaterClient
import LiveWebSocketClient

class AppDelegate: NSViewController, NSApplicationDelegate, NSWindowDelegate {
  let app = App()

  public func applicationDidFinishLaunching(_ notification: Notification) {
    self.app.send(.didFinishLaunching)

    // NB: wake/sleep notifications are NOT posted to NotificationCenter.default
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(AppDelegate.receiveSleep(_:)),
      name: NSWorkspace.willSleepNotification,
      object: nil,
    )

    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(AppDelegate.receiveWakeup(_:)),
      name: NSWorkspace.didWakeNotification,
      object: nil,
    )

    NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didLaunchApplicationNotification,
      object: nil,
      queue: nil,
    ) { [weak self] notification in
      if let app = notification
        .userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
        self?.app.send(.appLaunched(pid: app.processIdentifier))
      }
    }

    // NB: clock/tz changes are NOT posted to NSWorkspace.shared.notificationCenter
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.NSSystemClockDidChange,
      object: nil,
      queue: nil,
    ) { [weak self] _ in
      self?.app.send(.systemClockOrTimeZoneChanged)
    }

    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.NSSystemTimeZoneDidChange,
      object: nil,
      queue: nil,
    ) { [weak self] _ in
      self?.app.send(.systemClockOrTimeZoneChanged)
    }
  }

  public func applicationWillTerminate(_ notification: Notification) {
    self.app.send(.willTerminate)
    NSWorkspace.shared.notificationCenter.removeObserver(self)
  }

  @objc func receiveSleep(_ notification: Notification) {
    self.app.send(.willSleep)
  }

  @objc func receiveWakeup(_ notification: Notification) {
    self.app.send(.didWake)
  }
}
