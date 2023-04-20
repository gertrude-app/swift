import ComposableArchitecture

@MainActor public struct App {
  var menuBarManager: MenuBarManager
  var blockedRequestsWindow: BlockedRequestsWindow
  let store = Store(
    initialState: AppReducer.State(),
    reducer: AppReducer()._printChanges()
  )

  var statelessViewStore: ViewStore<Void, AppReducer.Action> {
    ViewStore(store.stateless)
  }

  public init() {
    menuBarManager = MenuBarManager(store: store.scope(
      state: { $0 },
      action: AppReducer.Action.menuBar
    ))
    blockedRequestsWindow = BlockedRequestsWindow(store: store.scope(
      state: { $0.blockedRequests },
      action: AppReducer.Action.blockedRequests
    ))
  }

  public func send(_ action: ApplicationAction) {
    switch action {
    case .didFinishLaunching:
      statelessViewStore.send(.application(.didFinishLaunching))
    case .willTerminate:
      statelessViewStore.send(.application(.willTerminate))
    }
  }
}
