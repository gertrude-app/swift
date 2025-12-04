import Cocoa
import Combine
import ComposableArchitecture
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
      self.webview = state.menuBarView
      self.dropdownOpen = state.menuBar.dropdownOpen
    }
  }

  init(store: Store<AppReducer.State, MenuBarFeature.Action>) {
    self.store = store
    self.viewStore = ViewStore(store, observe: ObservedState.init)

    self.popover = NSPopover()
    self.popover.animates = false
    self.popover.behavior = .applicationDefined

    if #available(macOS 14, *) {
      self.popover.hasFullSizeContent = true
      self.popover.contentSize = NSSize(width: 402, height: 302)
    } else {
      self.popover.contentSize = NSSize(width: 400, height: 300)
    }

    self.vc = WebViewController<MenuBarFeature.State.View, MenuBarFeature.Action>()
    self.popover.contentViewController = self.vc

    self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    self.statusItem.button?.image = NSImage(named: "MenuBarIcon.v2")
    self.statusItem.button?.image?.isTemplate = true // auto-coloring/inverting of image
    self.statusItem.button?.action = #selector(self.iconClicked(_:))
    self.statusItem.button?.target = self

    self.vc.send = { [weak self] action in
      self?.viewStore.send(action)
    }

    // send new state when store gets a change
    self.viewStore.publisher
      .receive(on: self.mainQueue)
      .sink { [weak self] _ in
        guard let self, self.vc.isReady.value else { return }
        self.vc.updateState(self.viewStore.state.webview)
      }.store(in: &self.cancellables)

    // respond to color scheme changes
    self.app.colorSchemeChanges()
      .receive(on: self.mainQueue)
      .sink { [weak self] colorScheme in
        guard let self, self.vc.isReady.value else { return }
        self.vc.updateColorScheme(colorScheme)
      }.store(in: &self.cancellables)

    // send the initial state when the webview is ready
    self.vc.isReady
      .receive(on: self.mainQueue)
      .prefix(2)
      .removeDuplicates()
      .sink { [weak self] ready in
        guard let self, ready else { return }
        self.vc.updateState(self.viewStore.state.webview)
        self.vc.updateColorScheme(self.app.colorScheme())
      }.store(in: &self.cancellables)

    self.vc.loadWebView(screen: "MenuBar")

    self.viewStore.publisher.dropdownOpen
      .receive(on: self.mainQueue)
      .dropFirst()
      .sink { [weak self] isOpen in
        guard let self else { return }
        self.setPopoverVisibility(to: isOpen)
      }.store(in: &self.cancellables)
  }

  @objc func iconClicked(_ sender: Any?) {
    self.viewStore.send(.menuBarIconClicked)
  }

  func setPopoverVisibility(to visible: Bool) {
    if !visible {
      self.popover.performClose(nil)
      return
    } else {
      guard let button = statusItem.button else { return }
      self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.maxY)

      // This is probably not necessary - added to ensure Gertrude is front application
      // when menu bar icon is clicked, so that webview hover/focus states always work.
      // It also helps ensure that any spawned windows are focused, though they also
      // take care to activate the app to ensure focus.
      NSApp.activate(ignoringOtherApps: true)

      self.popover.contentViewController?.view.window?.becomeKey()
    }
  }
}
