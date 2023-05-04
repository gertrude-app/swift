import App
import AppKit
import Cocoa
import LiveApiClient
import LiveFilterExtensionClient
import LiveFilterXPCClient
import LiveUpdaterClient

class AppDelegate: NSViewController, NSApplicationDelegate, NSWindowDelegate {
  let app = App()

  public func applicationDidFinishLaunching(_ notification: Notification) {
    app.send(.didFinishLaunching)
  }

  public func applicationWillTerminate(_ notification: Notification) {
    app.send(.willTerminate)
  }
}
