import Cocoa
import Combine
import ComposableArchitecture
import SwiftUI
import WebKit

@MainActor class MenuBarManager {
  let store: Store<AppReducer.State, MenuBarFeature.Action>
  var statusItem: NSStatusItem
  var popover: NSPopover
  var cancellables = Set<AnyCancellable>()
  var vc: WebViewController<MenuBarFeature.State, MenuBarFeature.Action>

  @ObservedObject var viewStore: ViewStore<MenuBarFeature.State, MenuBarFeature.Action>

  init(store: Store<AppReducer.State, MenuBarFeature.Action>) {
    self.store = store
    viewStore = ViewStore(store, observe: \.menuBar)

    popover = NSPopover()
    popover.animates = false
    popover.behavior = .applicationDefined

    vc = WebViewController<MenuBarFeature.State, MenuBarFeature.Action>()
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

    // send initial state after javascript parsed, evaluated, react ready
    // TODO: better would be to bootstrap this when setting up webview
    DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(1))) { [weak self] in
      guard let self = self else { return }
      self.vc.updateState(self.viewStore.state)
    }
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