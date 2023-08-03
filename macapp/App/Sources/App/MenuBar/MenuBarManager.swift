import Cocoa
import Combine
import ComposableArchitecture
import SwiftUI
import WebKit

@MainActor class MenuBarManager {
  let store: Store<AppReducer.State, MenuBarFeature.Action>
  var viewStore: ViewStore<ObservedState, MenuBarFeature.Action>
  var vc: WebViewController<MenuBarFeature.State.View, MenuBarFeature.Action>
  var statusItem: NSStatusItem
  var popover: NSPopover
  var cancellables = Set<AnyCancellable>()

  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.app) var app

  struct ObservedState: Equatable {
    var webview: MenuBarFeature.State.View
    var dropdownOpen: Bool

    init(_ state: AppReducer.State) {
      webview = state.menuBarView
      dropdownOpen = state.menuBar.dropdownOpen
    }
  }

  init(store: Store<AppReducer.State, MenuBarFeature.Action>) {
    self.store = store
    viewStore = ViewStore(store, observe: ObservedState.init)

    popover = NSPopover()
    popover.animates = false
    popover.behavior = .applicationDefined

    vc = WebViewController<MenuBarFeature.State.View, MenuBarFeature.Action>()
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
        self.vc.updateState(self.viewStore.state.webview)
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
        self.vc.updateState(self.viewStore.state.webview)
        self.vc.updateColorScheme(self.app.colorScheme())
      }.store(in: &cancellables)

    vc.loadWebView(screen: "MenuBar")

    viewStore.publisher.dropdownOpen
      .receive(on: mainQueue)
      .dropFirst()
      .sink { [weak self] isOpen in
        guard let self = self else { return }
        self.setPopoverVisibility(to: isOpen)
      }.store(in: &cancellables)
  }

  @objc func iconClicked(_ sender: Any?) {
    viewStore.send(.menuBarIconClicked)
  }

  func setPopoverVisibility(to visible: Bool) {
    if !visible {
      popover.performClose(nil)
      return
    } else {
      guard let button = statusItem.button else { return }
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.maxY)

      // This is probably not necessary - added to ensure Gertrude is front application
      // when menu bar icon is clicked, so that webview hover/focus states always work.
      // It also helps ensure that any spawned windows are focused, though they also
      // take care to activate the app to ensure focus.
      NSApp.activate(ignoringOtherApps: true)

      popover.contentViewController?.view.window?.becomeKey()
    }
  }
}
