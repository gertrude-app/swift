import Cocoa
import Foundation
import SwiftUI

class MenuBarPlugin: Plugin {
  var store: AppStore
  var menuBarItem: NSStatusItem
  var popover: NSPopover
  var timer: Timer?
  var filterRunning: Bool { store.state.filterStatus == .installedAndRunning }

  init(store: AppStore) {
    self.store = store

    popover = NSPopover()
    popover.animates = false
    popover.behavior = .transient

    menuBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    menuBarItem.button?.image = NSImage(named: "MenuBarIcon")
    menuBarItem.button?.image?.isTemplate = true // for auto-coloring/inverting of image
    menuBarItem.button?.action = #selector(togglePopover(_:))
    menuBarItem.button?.target = self

    render()
  }

  func sizePopover() {
    let (width, height) = MenuBarDropdown.dimensions(from: store)
    popover.contentSize = NSSize(width: width + 10, height: height + 10)
  }

  @objc func togglePopover(_ sender: AnyObject?) {
    if let button = menuBarItem.button {
      if popover.isShown {
        popover.performClose(sender)
      } else {
        sizePopover()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.maxY)
        popover.contentViewController?.view.window?.becomeKey()
      }
    }
  }

  func startSuspensionTimer() {
    timer = Timer.repeating(every: 10) { [weak self] _ in
      self?.render()
      if self?.store.state.filterSuspension?.isActive != true {
        self?.timer?.invalidate()
        self?.timer = nil
      }
    }
  }

  func render() {
    let view = MenuBarDropdown().environmentObject(store)
    popover.contentViewController = NSHostingController(rootView: view)
    sizePopover()
  }

  func respond(to event: AppEvent) {
    switch event {
    case
      .userTokenChanged,
      .keyloggingStateChanged,
      .screenshotsStateChanged,
      .filterStatusChanged,
      .cancelFilterSuspension:
      sizePopover()

    case .suspendFilter:
      sizePopover()
      startSuspensionTimer()

    case .closeMenuBarPopover:
      if popover.isShown {
        popover.performClose(nil)
      }

    default:
      break
    }
  }
}
