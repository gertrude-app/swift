import Cocoa
import ComposableArchitecture
import SwiftUI

@MainActor public class MenuBarManager {
  let store: StoreOf<MenuBar>
  let viewStore: ViewStore<Void, MenuBar.Action>
  var statusItem: NSStatusItem
  var popover: NSPopover

  public init(store: StoreOf<MenuBar>) {
    self.store = store
    viewStore = ViewStore(store.stateless)

    popover = NSPopover()
    popover.animates = false
    popover.behavior = .applicationDefined

    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.image = NSImage(named: "MenuBarIcon")
    statusItem.button?.image?.isTemplate = true // for auto-coloring/inverting of image
    statusItem.button?.action = #selector(iconClicked(_:))
    statusItem.button?.target = self

    let view = MenuBarView(store: self.store)
    popover.contentViewController = NSHostingController(rootView: view)
  }

  @objc func iconClicked(_ sender: Any?) {
    viewStore.send(.menuBarIconClicked)
    if popover.isShown {
      popover.performClose(sender)
      return
    }
    guard let button = statusItem.button else { return }
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.maxY)
    popover.contentViewController?.view.window?.becomeKey()
  }
}
