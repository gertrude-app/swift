import Cocoa
import Combine
import ComposableArchitecture
import SwiftUI
import WebKit

@MainActor public class MenuBarManager {
  let store: StoreOf<MenuBar>
  var statusItem: NSStatusItem
  var popover: NSPopover
  var cancellables = Set<AnyCancellable>()
  var vc: WebViewController<MenuBar.State.Screen, MenuBar.Action>

  @ObservedObject var viewStore: ViewStore<MenuBar.State.Screen, MenuBar.Action>

  public init(store: StoreOf<MenuBar>) {
    self.store = store
    viewStore = ViewStore(store, observe: \.screen)

    popover = NSPopover()
    popover.animates = false
    popover.behavior = .applicationDefined

    vc = WebViewController<MenuBar.State.Screen, MenuBar.Action>()
    vc.loadWebView(screen: "MenuBar")
    popover.contentViewController = vc
    popover.contentSize = NSSize(width: 400, height: 300)

    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.image = NSImage(named: "MenuBarIcon")
    statusItem.button?.image?.isTemplate = true // auto-coloring/inverting of image
    statusItem.button?.action = #selector(iconClicked(_:))
    statusItem.button?.target = self

    vc.send = { [weak self] action in
      self?.viewStore.send(action)
    }

    // send new state when store gets a change
    viewStore.objectWillChange.sink { _ in
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.vc.updateState(self.viewStore.state)
      }
    }.store(in: &cancellables)
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
