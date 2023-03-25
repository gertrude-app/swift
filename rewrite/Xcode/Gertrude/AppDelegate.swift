import App
import AppKit
import Cocoa
import LiveApiClient
import LiveFilterClient

class AppDelegate: NSViewController, NSApplicationDelegate, NSWindowDelegate {
  let app = App()

  public func applicationDidFinishLaunching(_ notification: Notification) {
    app.send(delegate: .didFinishLaunching)
  }
}
