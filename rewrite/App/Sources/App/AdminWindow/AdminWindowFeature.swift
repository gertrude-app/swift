import ComposableArchitecture
import Foundation
import Shared

struct AdminWindowFeature: Feature {
  enum Screen: String, Equatable, Codable {
    case home
    case healthCheck
    case exemptUsers
  }

  struct State: Equatable {
    struct HealthCheck: Equatable, Encodable {
      enum FilterStatus: Equatable, Codable {
        case installing
        case installTimeout
        case notInstalled
        case unexpected
        case communicationBroken
        case installed(version: String, numUserKeys: Int)
      }

      var latestAppVersion: Failable<String>?
      var filterStatus: FilterStatus?
      var accountStatus: Failable<AdminAccountStatus>?
      var screenRecordingPermissionOk: Bool?
      var keystrokeRecordingPermissionOk: Bool?
      var macOsUserType: Failable<MacOsUserType>?
      var notificationsSetting: NotificationsSetting?
    }

    var windowOpen = false
    var screen: Screen = .healthCheck
    var healthCheck: HealthCheck = .init()
  }

  enum Action: Equatable, Sendable {
    enum View: Equatable, Sendable, Decodable {
      enum HealthCheckAction: String, Equatable, Sendable, Codable {
        case recheckClicked
        case upgradeAppClicked
        case installFilterClicked
        case repairFilterCommunicationClicked
        case repairOutOfDateFilterClicked
        case fixScreenRecordingPermissionClicked
        case fixKeystrokeRecordingPermissionClicked
        case removeUserAdminPrivilegeClicked
        case fixNotificationPermissionClicked
        case zeroKeysRefreshRulesClicked
      }

      case closeWindow
      case healthCheck(action: HealthCheckAction)
      case gotoScreenClicked(screen: Screen)
    }

    enum Delegate: Equatable, Sendable {
      case triggerAppUpdate
    }

    case openWindow
    case closeWindow
    case setScreenRecordingPermissionOk(Bool)
    case setKeystrokeRecordingPermissionOk(Bool)
    case setNotificationsSetting(NotificationsSetting)
    case setMacOsUserType(Failable<MacOsUserType>)
    case setFilterStatus(State.HealthCheck.FilterStatus)
    case webview(View)
    case delegate(Delegate)
    case healthCheckTimeout
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.app) var app
    @Dependency(\.device) var device
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.filterExtension) var filter

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      .none
    }
  }

  struct RootReducer: RootReducing {
    @Dependency(\.app) var app
    @Dependency(\.api) var api
    @Dependency(\.device) var device
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.filterExtension) var filter
    @Dependency(\.mainQueue) var mainQueue
  }
}

private enum CancelId {
  case healthCheckTimeout
}

extension AdminWindowFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .menuBar(.administrateClicked),
         .adminWindow(.openWindow),
         .adminWindow(.webview(.healthCheck(.recheckClicked))):

      state.adminWindow.windowOpen = true
      state.adminWindow.healthCheck = .init()
      let keyloggingEnabled = state.user?.keyloggingEnabled == true
      let screenRecordingEnabled = state.user?.screenshotsEnabled == true

      let main = Effect<Action>.run { [releaseChannel = state.appUpdates.releaseChannel] send in
        try await mainQueue.sleep(for: .seconds(1))

        async let accountStatus = TaskResult { try await api.getAdminAccountStatus() }
        async let latestAppVersion = TaskResult { try await api.latestAppVersion(releaseChannel) }

        await send(.admin(.accountStatusResponse(accountStatus)))
        await send(.appUpdates(.latestVersionResponse(latestAppVersion)))

        await send(.adminWindow(.setKeystrokeRecordingPermissionOk(
          keyloggingEnabled ? await device.keystrokeRecordingPermissionGranted() : true
        )))

        await send(.adminWindow(.setScreenRecordingPermissionOk(
          screenRecordingEnabled ? await device.screenRecordingPermissionGranted() : true
        )))

        await send(.adminWindow(.setNotificationsSetting(
          await device.notificationsSetting()
        )))

        await send(.adminWindow(.setMacOsUserType(
          .init { try await device.currentMacOsUserType() }
        )))

        await recheckFilter(send)

        try await mainQueue.sleep(for: .seconds(10))

        await send(.adminWindow(.healthCheckTimeout))
      }.cancellable(id: CancelId.healthCheckTimeout, cancelInFlight: true)

      return .merge(
        main,
        action == .adminWindow(.webview(.healthCheck(action: .recheckClicked)))
          ? .cancel(id: CancelId.healthCheckTimeout) : .none
      )

    case .admin(.accountStatusResponse(.success(let status))):
      state.adminWindow.healthCheck.accountStatus = .ok(value: status)
      return state.adminWindow.healthCheck.checkCompletionEffect

    case .admin(.accountStatusResponse(.failure)):
      state.adminWindow.healthCheck.accountStatus = .error
      return state.adminWindow.healthCheck.checkCompletionEffect

    case .appUpdates(.latestVersionResponse(.success(let version))):
      state.adminWindow.healthCheck.latestAppVersion = .ok(value: version)
      return state.adminWindow.healthCheck.checkCompletionEffect

    case .user(.refreshRules(.success, _)):
      return .run { send in
        // wait for feature reducer to send rules to filter
        try await mainQueue.sleep(for: .milliseconds(10))
        await recheckFilter(send)
      }

    case .adminWindow(let adminWindowAction):

      switch adminWindowAction {
      case .openWindow, .webview(.healthCheck(.recheckClicked)):
        return .none // handled above

      case .closeWindow,
           .webview(.closeWindow):
        state.adminWindow.windowOpen = false
        return .none

      case .webview(.gotoScreenClicked(let screen)):
        state.adminWindow.screen = screen
        return .none

      case .webview(.healthCheck(.fixKeystrokeRecordingPermissionClicked)):
        return .run { _ in
          await device.openSystemPrefs(.security(.accessibility))
        }

      case .webview(.healthCheck(.fixScreenRecordingPermissionClicked)):
        return .run { _ in
          await device.openSystemPrefs(.security(.screenRecording))
        }

      case .webview(.healthCheck(.removeUserAdminPrivilegeClicked)):
        return .run { _ in
          await device.openSystemPrefs(.accounts)
        }

      case .webview(.healthCheck(.fixNotificationPermissionClicked)):
        return .run { _ in
          await device.openSystemPrefs(.notifications)
        }

      // TODO: release channel should be cross-user concern, we can't have one user
      // on beta with the filter on beta, and another user on stable 🤔
      // maybe it should be stored in the api on the `device`

      case .webview(.healthCheck(.repairOutOfDateFilterClicked)):
        state.adminWindow.healthCheck.filterStatus = nil
        return .merge(
          .run { try await replaceFilter($0, retryOnce: true) },
          withTimeoutAfter(seconds: 5)
        )

      case .webview(.healthCheck(.installFilterClicked)):
        state.adminWindow.healthCheck.filterStatus = .installing
        return .merge(
          .run { try await installFilter($0) },
          withTimeoutAfter(seconds: 60)
        )

      case .webview(.healthCheck(.repairFilterCommunicationClicked)):
        return .merge(
          .run { send in
            try await restartFilter(send)
            try await mainQueue.sleep(for: .milliseconds(10))
            if (await xpc.isConnectionHealthy()).isFailure {
              try await replaceFilter(send, retryOnce: true)
            }
          },
          withTimeoutAfter(seconds: 5)
        )

      case .webview(.healthCheck(.zeroKeysRefreshRulesClicked)):
        state.adminWindow.healthCheck.filterStatus = nil
        return withTimeoutAfter(seconds: 10)

      case .webview(.healthCheck(.upgradeAppClicked)):
        return .run { send in await send(.adminWindow(.delegate(.triggerAppUpdate))) }

      case .setNotificationsSetting(let setting):
        state.adminWindow.healthCheck.notificationsSetting = setting
        return state.adminWindow.healthCheck.checkCompletionEffect

      case .setScreenRecordingPermissionOk(let granted):
        state.adminWindow.healthCheck.screenRecordingPermissionOk = granted
        return state.adminWindow.healthCheck.checkCompletionEffect

      case .setKeystrokeRecordingPermissionOk(let granted):
        state.adminWindow.healthCheck.keystrokeRecordingPermissionOk = granted
        return state.adminWindow.healthCheck.checkCompletionEffect

      case .setMacOsUserType(let userType):
        state.adminWindow.healthCheck.macOsUserType = userType
        return state.adminWindow.healthCheck.checkCompletionEffect

      case .setFilterStatus(let filterStatus):
        state.adminWindow.healthCheck.filterStatus = filterStatus
        return state.adminWindow.healthCheck.checkCompletionEffect

      case .healthCheckTimeout:
        state.adminWindow.healthCheck.setPendingChecksToError()
        return .none

      case .delegate:
        return .none
      }

    default:
      return .none
    }
  }

  func withTimeoutAfter(seconds: Int) -> Effect<Action> {
    .run { send in
      try await mainQueue.sleep(for: .seconds(seconds))
      await send(.adminWindow(.healthCheckTimeout))
    }.cancellable(id: CancelId.healthCheckTimeout, cancelInFlight: true)
  }

  func recheckFilter(_ send: Send<Action>) async {
    switch await filter.state() {
    case .notInstalled:
      await send(.adminWindow(.setFilterStatus(.notInstalled)))
      return
    case .errorLoadingConfig, .unknown:
      await send(.adminWindow(.setFilterStatus(.unexpected)))
      return
    case .on, .off, .suspended:
      switch await xpc.requestAck() {
      case .success(let ack) where ack.userId == getuid():
        await send(.adminWindow(.setFilterStatus(
          .installed(version: ack.version, numUserKeys: ack.numUserKeys)
        )))
      case .success(let ack):
        await send(.adminWindow(.setFilterStatus(
          .installed(version: ack.version, numUserKeys: 0)
        )))
      case .failure:
        await send(.adminWindow(.setFilterStatus(.communicationBroken)))
      }
    }
  }

  func installFilter(_ send: Send<Action>) async throws {
    _ = await filter.install()
    try await mainQueue.sleep(for: .milliseconds(10))
    _ = await xpc.establishConnection()
    await recheckFilter(send)
  }

  func restartFilter(_ send: Send<Action>) async throws {
    _ = await filter.restart()
    try await mainQueue.sleep(for: .milliseconds(100))
    _ = await xpc.establishConnection()
    await recheckFilter(send)
  }

  func replaceFilter(_ send: Send<Action>, retryOnce retry: Bool = false) async throws {
    _ = await filter.replace()
    try await mainQueue.sleep(for: .milliseconds(500))
    _ = await xpc.establishConnection()
    await recheckFilter(send)
    if retry, (await xpc.isConnectionHealthy()).isFailure {
      try await replaceFilter(send, retryOnce: false)
    }
  }

  func replaceFilterIfNotConnected(_ send: Send<Action>, retryOnce: Bool = false) async throws {
    if (await xpc.isConnectionHealthy()).isFailure {
      try await replaceFilter(send, retryOnce: retryOnce)
    }
  }
}

extension AdminWindowFeature.State {
  struct View: Equatable, Encodable {
    var windowOpen = false
    var screen: AdminWindowFeature.Screen
    var healthCheck: HealthCheck
    var filterState: FilterState
    var userName: String
    var screenshotMonitoringEnabled: Bool
    var keystrokeMonitoringEnabled: Bool
    var installedAppVersion: String
  }
}

extension AdminWindowFeature.State.HealthCheck {
  mutating func setPendingChecksToError() {
    if latestAppVersion == nil { latestAppVersion = .error }
    if filterStatus == .installing { filterStatus = .installTimeout }
    if filterStatus == nil { filterStatus = .unexpected }
    if accountStatus == nil { accountStatus = .error }
    if macOsUserType == nil { macOsUserType = .error }
  }

  var isComplete: Bool {
    if latestAppVersion == nil { return false }
    if filterStatus == nil { return false }
    if accountStatus == nil { return false }
    if macOsUserType == nil { return false }
    if notificationsSetting == nil { return false }
    if screenRecordingPermissionOk == nil { return false }
    if keystrokeRecordingPermissionOk == nil { return false }
    return true
  }

  var checkCompletionEffect: Effect<AppReducer.Action> {
    isComplete ? Effect.cancel(id: CancelId.healthCheckTimeout) : .none
  }
}

extension AdminWindowFeature.State.View {
  init(rootState: AppReducer.State) {
    @Dependency(\.app) var app
    let featureState = rootState.adminWindow
    windowOpen = featureState.windowOpen
    screen = featureState.screen
    healthCheck = featureState.healthCheck
    filterState = rootState.filter.shared
    userName = rootState.user?.name ?? ""
    screenshotMonitoringEnabled = rootState.user?.screenshotsEnabled ?? false
    keystrokeMonitoringEnabled = rootState.user?.keyloggingEnabled ?? false
    installedAppVersion = app.installedVersion() ?? "0.0.0"
  }
}

extension AdminWindowFeature.Reducer {
  typealias State = AdminWindowFeature.State
  typealias Action = AdminWindowFeature.Action
}