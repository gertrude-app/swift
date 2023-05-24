import Cocoa
import Combine
import ComposableArchitecture
import SwiftUI
import WebKit

@MainActor class MenuBarManager {
  let store: Store<AppReducer.State, MenuBarFeature.Action>
  var viewStore: ViewStore<MenuBarFeature.State, MenuBarFeature.Action>
  var vc: WebViewController<MenuBarFeature.State, MenuBarFeature.Action>
  var statusItem: NSStatusItem
  var popover: NSPopover
  var cancellables = Set<AnyCancellable>()

  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.app) var app

  init(store: Store<AppReducer.State, MenuBarFeature.Action>) {
    self.store = store
    viewStore = ViewStore(store, observe: \.menuBar)

    popover = NSPopover()
    popover.animates = false
    popover.behavior = .applicationDefined

    vc = WebViewControllerOf<MenuBarFeature>()
    popover.contentViewController = vc
    popover.contentSize = NSSize(width: 400, height: 300)

    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.image = NSImage(named: "MenuBarIcon.v2")
    statusItem.button?.image?.isTemplate = true // auto-coloring/inverting of image
    statusItem.button?.action = #selector(iconClicked(_:))
    statusItem.button?.target = self

    vc.send = { [weak self] action in
      self?.viewStore.send(action)
    }

    // send new state when store gets a change
    viewStore.publisher
      .receive(on: mainQueue)
      .sink { [weak self] _ in
        guard let self = self, self.vc.isReady.value else { return }
        self.vc.updateState(self.viewStore.state)
      }.store(in: &cancellables)

    // respond to color scheme changes
    app.colorSchemeChanges()
      .receive(on: mainQueue)
      .sink { [weak self] colorScheme in
        guard let self = self, self.vc.isReady.value else { return }
        self.vc.updateColorScheme(colorScheme)
      }.store(in: &cancellables)

    // send the initial state when the webview is ready
    vc.isReady
      .receive(on: mainQueue)
      .prefix(2)
      .removeDuplicates()
      .sink { [weak self] ready in
        guard let self = self, ready else { return }
        self.vc.updateState(self.viewStore.state)
        self.vc.updateColorScheme(self.app.colorScheme())
      }.store(in: &cancellables)

    vc.loadWebView(screen: "MenuBar")
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
