import Foundation
import SwiftUI

protocol WindowPlugin: NSObject, NSWindowDelegate, StorePlugin {
  var windowOpen: Bool { get set }
  var initialDims: (width: CGFloat, height: CGFloat) { get }
  var title: String { get }
  var contentView: NSView { get }
  var window: NSWindow? { get set }
  func windowWillClose(_ notification: Notification)
}

// @TODO: TEMP
enum WindowDims {
  struct Dims {
    let minWidth: CGFloat
    let minHeight: CGFloat
  }

  static let admin = Dims(minWidth: 700, minHeight: 400)
}

extension WindowPlugin {
  var initialDims: (width: CGFloat, height: CGFloat) {
    (width: WindowDims.admin.minWidth, height: WindowDims.admin.minHeight)
  }

  func openWindow() {
    guard !windowOpen else {
      return
    }

    let (width, height) = initialDims
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: width, height: height),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )

    window?.center()
    window?.title = title
    window?.makeKeyAndOrderFront(nil)
    window?.isReleasedWhenClosed = false
    window?.delegate = self
    window?.contentView = contentView
    window?.tabbingMode = .disallowed

    windowOpen = true
    NSApp.activate(ignoringOtherApps: true)
  }
}
