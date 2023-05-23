import ComposableArchitecture

@MainActor public struct App {
  var menuBarManager: MenuBarManager
  var blockedRequestsWindow: BlockedRequestsWindow
  var adminWindow: AdminWindow
  var requestSuspensionWindow: RequestSuspensionWindow
  let store = Store(
    initialState: AppReducer.State(),
    reducer: AppReducer()._printChanges(.filteredBy { action in
      switch action {
      case .user(.refreshRules(.success, _)):
        print("received action:\n  .user(.refreshRules(.success(...)))\n")
        return false
      default:
        return true
      }
    })
  )

  var statelessViewStore: ViewStore<Void, AppReducer.Action> {
    ViewStore(store.stateless)
  }

  public init() {
    menuBarManager = MenuBarManager(store: store.scope(
      state: { $0 },
      action: AppReducer.Action.menuBar
    ))
    adminWindow = AdminWindow(store: store.scope(
      state: { $0 },
      action: AppReducer.Action.adminWindow
    ))
    blockedRequestsWindow = BlockedRequestsWindow(store: store.scope(
      state: { $0 },
      action: AppReducer.Action.blockedRequests
    ))
    requestSuspensionWindow = RequestSuspensionWindow(store: store.scope(
      state: { $0 },
      action: AppReducer.Action.requestSuspension
    ))
  }

  public func send(_ action: ApplicationAction) {
    switch action {
    case .didFinishLaunching:
      statelessViewStore.send(.application(.didFinishLaunching))
    case .willSleep:
      statelessViewStore.send(.application(.willSleep))
    case .didWake:
      statelessViewStore.send(.application(.didWake))
    case .willTerminate:
      statelessViewStore.send(.application(.willTerminate))
    }
  }
}
