import ComposableArchitecture

@MainActor public struct App {
  var menuBarManager: MenuBarManager
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
  }

  public func send(delegate action: AppDelegateAction) {
    switch action {
    case .didFinishLaunching:
      statelessViewStore.send(.delegate(.didFinishLaunching))
    }
  }
}
