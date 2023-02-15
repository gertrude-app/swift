import Cocoa
import Combine
import ComposableArchitecture
import SwiftUI

@MainActor public class MenuBarManager {
  let store: StoreOf<MenuBar>
  var statusItem: NSStatusItem
  var popover: NSPopover
  var cancellables = Set<AnyCancellable>()

  @ObservedObject var viewStore: ViewStore<MenuBar.State.User?, MenuBar.Action>

  public init(store: StoreOf<MenuBar>) {
    self.store = store
    viewStore = ViewStore(store, observe: \.user)

    popover = NSPopover()
    popover.animates = false
    popover.behavior = .applicationDefined

    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.image = NSImage(named: "MenuBarIcon")
    statusItem.button?.image?.isTemplate = true // auto-coloring/inverting of image
    statusItem.button?.action = #selector(iconClicked(_:))
    statusItem.button?.target = self

    let view = MenuBarView(store: self.store)
    popover.contentViewController = NSHostingController(rootView: view)
    sizePopover()

    // resize popover when store gets a change
    viewStore.objectWillChange.sink { _ in
      DispatchQueue.main.async { [weak self] in
        self?.sizePopover()
      }
    }.store(in: &cancellables)
  }

  func sizePopover() {
    let (width, height) = viewStore.state?.viewDimensions ?? MenuBar.State().viewDimensions
    popover.contentSize = NSSize(width: width, height: height)
  }

  @objc func iconClicked(_ sender: Any?) {
    viewStore.send(.menuBarIconClicked)
    if popover.isShown {
      popover.performClose(sender)
      return
    }
    guard let button = statusItem.button else { return }
    sizePopover()
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.maxY)
    popover.contentViewController?.view.window?.becomeKey()
  }
}
