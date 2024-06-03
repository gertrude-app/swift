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

    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(AppDelegate.receiveSleep(_:)),
      name: NSWorkspace.willSleepNotification,
      object: nil
    )

    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(AppDelegate.receiveWakeup(_:)),
      name: NSWorkspace.didWakeNotification,
      object: nil
    )
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
