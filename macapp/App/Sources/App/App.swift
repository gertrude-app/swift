import ClientInterfaces
import ComposableArchitecture
import Dependencies
import Gertie
import MacAppRoute

@MainActor public struct App {
  var menuBarManager: MenuBarManager
  var blockedRequestsWindow: BlockedRequestsWindow
  var adminWindow: AdminWindow
  var requestSuspensionWindow: RequestSuspensionWindow
  var onboardingWindow: OnboardingWindow
  let store = Store(
    initialState: AppReducer.State(appVersion: {
      @Dependency(\.app) var appClient
      return appClient.installedVersion()
    }()),
    reducer: {
      AppReducer()._printChanges(.filteredBy { action in
        switch action {
        case .checkIn(.success, _):
          print("received action:\n  .checkIn(.success(...))\n")
          return false
        case .menuBar(.menuBarIconClicked):
          print("received action:\n  .menuBar(.menuBarIconClicked)\n")
          return false
        default:
          return true
        }
      })
    }
  )

  public init() {
    self.menuBarManager = MenuBarManager(store: self.store.scope(
      state: { $0 },
      action: AppReducer.Action.menuBar
    ))
    self.adminWindow = AdminWindow(store: self.store.scope(
      state: { $0 },
      action: AppReducer.Action.adminWindow
    ))
    self.blockedRequestsWindow = BlockedRequestsWindow(store: self.store.scope(
      state: { $0 },
      action: AppReducer.Action.blockedRequests
    ))
    self.requestSuspensionWindow = RequestSuspensionWindow(store: self.store.scope(
      state: { $0 },
      action: AppReducer.Action.requestSuspension
    ))
    self.onboardingWindow = OnboardingWindow(store: self.store.scope(
      state: { $0 },
      action: AppReducer.Action.onboarding
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
      self.store.send(.application(.didFinishLaunching))
    case .willSleep:
      self.store.send(.application(.willSleep))
    case .didWake:
      self.store.send(.application(.didWake))
    case .willTerminate:
      self.store.send(.application(.willTerminate))
    case .systemClockOrTimeZoneChanged:
      self.store.send(.application(.systemClockOrTimeZoneChanged))
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
