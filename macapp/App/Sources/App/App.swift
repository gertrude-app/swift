import ClientInterfaces
import ComposableArchitecture
import Dependencies
import MacAppRoute

typealias UserData = GetUserData.Output

@MainActor public struct App {
  var menuBarManager: MenuBarManager
  var blockedRequestsWindow: BlockedRequestsWindow
  var adminWindow: AdminWindow
  var requestSuspensionWindow: RequestSuspensionWindow
  let store = Store(
    initialState: AppReducer.State(),
    reducer: {
      AppReducer()._printChanges(.filteredBy { action in
        switch action {
        case .checkIn(.success, _):
          print("received action:\n  .checkIn(.success(...))\n")
          return false
        default:
          return true
        }
      })
    }
  )

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

    #if !DEBUG
      setEventReporter { kind, eventId, detail in
        @Dependency(\.api) var apiClient
        @Dependency(\.storage) var storageClient
        let deviceId = try? await storageClient.loadPersistentState()?.user?.deviceId
        await apiClient.logInterestingEvent(.init(
          eventId: eventId,
          kind: kind,
          deviceId: deviceId,
          detail: detail
        ))
      }
    #endif
  }

  public func send(_ action: ApplicationAction) {
    switch action {
    case .didFinishLaunching:
      store.send(.application(.didFinishLaunching))
    case .willSleep:
      store.send(.application(.willSleep))
    case .didWake:
      store.send(.application(.didWake))
    case .willTerminate:
      store.send(.application(.willTerminate))
    }
  }
}

#if DEBUG
  import Darwin

  func eprint(_ items: Any...) {
    let s = items.map { "\($0)" }.joined(separator: " ")
    fputs(s + "\n", stderr)
    fflush(stderr)
  }
#endif
