import ClientInterfaces
import Combine
import ComposableArchitecture
import Core
import Foundation
import Gertie
import MacAppRoute
import os.log

struct TrustedTimestamp: Equatable {
  var network: Date
  var system: Date
  var boottime: Date

  var networkSystemDelta: TimeInterval {
    self.network.timeIntervalSince(self.system)
  }
}

struct AppReducer: Reducer, Sendable {
  struct State: Equatable, Sendable {
    var admin = AdminFeature.State()
    var adminWindow = AdminWindowFeature.State()
    var appUpdates: AppUpdatesFeature.State
    var blockedRequests = BlockedRequestsFeature.State()
    var browsers: [BrowserMatch] = []
    var filter: FilterFeature.State
    var history = HistoryFeature.State()
    var menuBar = MenuBarFeature.State()
    var onboarding = OnboardingFeature.State()
    var monitoring = MonitoringFeature.State()
    var requestSuspension = RequestSuspensionFeature.State()
    var user = UserFeature.State()
    var timestamp: TrustedTimestamp?

    init(appVersion: String?) {
      self.appUpdates = .init(installedVersion: appVersion)
      self.filter = .init(appVersion: appVersion)
    }
  }

  enum CancelId {
    case heartbeatInterval
    case websocketMessages
    case networkConnectionChanges
  }

  enum Action: Equatable, Sendable {
    enum Delegate: Equatable, Sendable {
      case filterSuspendedChanged(was: Bool, is: Bool)
    }

    enum FocusedNotification: Equatable, Sendable {
      case unexpectedError
      case text(String, String)
    }

    case admin(AdminFeature.Action)
    case adminWindow(AdminWindowFeature.Action)
    case application(ApplicationFeature.Action)
    case appUpdates(AppUpdatesFeature.Action)
    case checkIn(result: TaskResult<CheckIn_v2.Output>, reason: CheckIn.Reason)
    case delegate(Delegate)
    case filter(FilterFeature.Action)
    case focusedNotification(FocusedNotification)
    case xpc(XPCEvent.App)
    case history(HistoryFeature.Action)
    case menuBar(MenuBarFeature.Action)
    case monitoring(MonitoringFeature.Action)
    case onboarding(OnboardingFeature.Action)
    case loadedPersistentState(Persistent.State?)
    case user(UserFeature.Action)
    case heartbeat(HeartbeatInterval)
    case blockedRequests(BlockedRequestsFeature.Action)
    case requestSuspension(RequestSuspensionFeature.Action)
    case startProtecting(user: UserData)
    case websocket(WebSocketFeature.Action)
    case setTrustedTimestamp(TrustedTimestamp)
    case networkConnectionChanged(connected: Bool)

    indirect case adminAuthed(Action)
  }

  @Dependency(\.api) var api
  @Dependency(\.app) var app
  @Dependency(\.device) var device
  @Dependency(\.backgroundQueue) var bgQueue
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.network) var network
  @Dependency(\.storage) var storage
  @Dependency(\.websocket) var websocket
  @Dependency(\.filterXpc) var xpc

  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      #if !DEBUG
        os_log("[G•] APP received action: %{public}@", String(describing: action))
      #endif

      switch action {
      case .loadedPersistentState(.none):
        state.onboarding.windowOpen = true
        return .exec { [new = state.persistent] _ in
          try await self.storage.savePersistentState(new)
        }

      case .loadedPersistentState(.some(let persisted)):
        state.appUpdates.releaseChannel = persisted.appUpdateReleaseChannel
        state.filter.version = persisted.filterVersion
        var effects: [Effect<Action>] = []
        if let user = persisted.user {
          state.user = .init(data: user)
          if persisted.resumeOnboarding == nil ||
            persisted.resumeOnboarding == .checkingFullDiskAccessPermission(upgrade: true) {
            effects.append(.exec { send in await send(.startProtecting(user: user)) })
          } else {
            state.onboarding.connectChildRequest = .succeeded(payload: user.name)
          }
        }
        if let onboardingStep = persisted.resumeOnboarding {
          effects.append(.exec { send in
            await send(.onboarding(.resume(onboardingStep)))
          })
          effects.append(.exec { [persist = state.persistent] _ in
            var withoutResume = persist
            withoutResume.resumeOnboarding = nil
            try await self.storage.savePersistentState(withoutResume)
          })
        }
        return .merge(effects)

      case .startProtecting(let user):
        let onboardingWindowOpen = state.onboarding.windowOpen
        return .merge(
          .exec { [filterVersion = state.filter.version] send in
            await self.api.setUserToken(user.token)
            guard self.network.isConnected() else { return }
            await send(.checkIn(
              result: TaskResult { try await self.api.appCheckIn(filterVersion) },
              reason: .startProtecting
            ))
          },

          .exec { _ in
            if onboardingWindowOpen == false, await (self.app.isLaunchAtLoginEnabled()) == false {
              await self.app.enableLaunchAtLogin()
            }
          },

          .publisher {
            self.websocket.receive()
              .map { .websocket(.receivedMessage($0)) }
              .receive(on: self.mainQueue)
          }.cancellable(id: CancelId.websocketMessages),

          .publisher {
            self.network.connectionChanges()
              .map { .networkConnectionChanged(connected: $0) }
              .receive(on: self.mainQueue)
          }.cancellable(id: CancelId.networkConnectionChanges),

          .exec { send in
            var numTicks = 0
            for await _ in self.bgQueue.timer(interval: .seconds(60)) {
              numTicks += 1
              for interval in heartbeatIntervals(for: numTicks) {
                await send(.heartbeat(interval))
              }
            }
          }.cancellable(id: CancelId.heartbeatInterval),

          .exec { _ in
            try await self.app.startRelaunchWatcher()
          },

          .exec { _ in
            await self.preventScreenCaptureNag()
          }
        )

      case .heartbeat(.everySixHours):
        return .exec { _ in
          await self.preventScreenCaptureNag()
        }

      case .focusedNotification(let notification):
        // dismiss windows/dropdowns so notification is visible, i.e. "focused"
        state.adminWindow.windowOpen = false
        state.menuBar.dropdownOpen = false
        state.blockedRequests.windowOpen = false
        state.requestSuspension.windowOpen = false
        return .exec { _ in
          switch notification {
          case .unexpectedError:
            await self.device.notifyUnexpectedError()
          case .text(let title, let body):
            await self.device.showNotification(title, body)
          }
        }

      case .onboarding(.delegate(.saveForResume(let resume))):
        OnboardingFeature.Reducer()
          .log("save for resume: \(String(describing: resume))", "93e00bac")
        return .exec { [persist = state.persistent] _ in
          var copy = persist
          copy.resumeOnboarding = resume
          try await self.storage.savePersistentState(copy)
        }

      case .onboarding(.delegate(.onboardingConfigComplete)):
        OnboardingFeature.Reducer().log("onboarding config complete", "079cbee4")
        if let user = state.user.data {
          return .exec { send in await send(.startProtecting(user: user)) }
        } else {
          return .none
        }

      case .setTrustedTimestamp(let timestamp):
        state.timestamp = timestamp
        return .none

      case .networkConnectionChanged(connected: true):
        return .exec { _ in _ = await self.xpc.sendAlive() }

      default:
        return .none
      }
    }

    // root reducers
    ApplicationFeature.RootReducer()
    HistoryFeature.RootReducer()
    UserFeature.RootReducer()
    BlockedRequestsFeature.RootReducer()
    AppUpdatesFeature.RootReducer()
    AdminFeature.RootReducer()
    AdminWindowFeature.RootReducer()
    FilterFeature.RootReducer().onChange(of: \.isFilterSuspended) { old, new in
      Reduce { _, _ in .run { send in
        // NB: changing this to the (synchronous?) `.send()` (without .run + async)
        // caused this action not to be seen by other reducers (when running app)
        await send(.delegate(.filterSuspendedChanged(was: old, is: new)))
      }}
    }
    MonitoringFeature.RootReducer()
    RequestSuspensionFeature.RootReducer()
    WebSocketFeature.RootReducer()
    UserConnectionFeature.RootReducer()
    MenuBarFeature.RootReducer()
    CheckInFeature.RootReducer()

    // feature reducers
    Scope(state: \.history, action: /Action.history) {
      HistoryFeature.Reducer()
    }
    Scope(state: \.filter, action: /Action.filter) {
      FilterFeature.Reducer()
    }
    Scope(state: \.menuBar, action: /Action.menuBar) {
      MenuBarFeature.Reducer()
    }
    Scope(state: \.blockedRequests, action: /Action.blockedRequests) {
      BlockedRequestsFeature.Reducer()
    }
    Scope(state: \.admin, action: /Action.admin) {
      AdminFeature.Reducer()
    }
    Scope(state: \.appUpdates, action: /Action.appUpdates) {
      AppUpdatesFeature.Reducer()
    }
    Scope(state: \.requestSuspension, action: /Action.requestSuspension) {
      RequestSuspensionFeature.Reducer()
    }
    Scope(state: \.user, action: /Action.user) {
      UserFeature.Reducer()
    }
    Scope(state: \.onboarding, action: /Action.onboarding) {
      OnboardingFeature.Reducer()
    }
  }

  func preventScreenCaptureNag() async {
    guard await self.app.hasFullDiskAccess() else {
      os_log("[G•] Skip preventScreenCaptureNag, missing full disk access")
      return
    }
    switch await self.app.preventScreenCaptureNag() {
    case .success:
      break
    case .failure(let error):
      unexpectedError(id: "3d2a5573", detail: error.message)
    }
  }
}
