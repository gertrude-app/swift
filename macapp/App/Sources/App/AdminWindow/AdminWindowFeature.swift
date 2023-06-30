import ClientInterfaces
import ComposableArchitecture
import Core
import Foundation
import Gertie
import TaggedTime

struct AdminWindowFeature: Feature {
  enum Screen: String, Equatable, Codable {
    case home
    case healthCheck
    case exemptUsers
    case advanced
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
      var macOsUserType: Failable<MacOSUserType>?
      var notificationsSetting: NotificationsSetting?
    }

    var windowOpen = false
    var screen: Screen = .home
    var healthCheck: HealthCheck = .init()
    var quitting = false
    var exemptableUsers: Failable<[MacOSUser]>?
    var exemptUserIds: Failable<[uid_t]>?
    var recentAppVersions: [String: String]?

    struct View: Equatable, Encodable {
      var windowOpen = false
      var screen: AdminWindowFeature.Screen
      var healthCheck: HealthCheck
      var filterState: FilterState
      var userName: String
      var screenshotMonitoringEnabled: Bool
      var keystrokeMonitoringEnabled: Bool
      var installedAppVersion: String
      var releaseChannel: ReleaseChannel
      var quitting: Bool

      struct ExemptableUser: Equatable, Codable {
        var id: uid_t
        var name: String
        var isAdmin: Bool
        var isExempt: Bool
      }

      var exemptableUsers: Failable<[ExemptableUser]>?

      struct Advanced: Equatable, Codable {
        var pairqlEndpointOverride: String?
        var pairqlEndpointDefault: String
        var websocketEndpointOverride: String?
        var websocketEndpointDefault: String
        var appcastEndpointOverride: String?
        var appcastEndpointDefault: String
        var appVersions: [String: String]?
      }

      var advanced: Advanced?
    }
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

      enum AdvancedAction: Equatable, Sendable, Codable {
        case pairqlEndpointSet(url: String?)
        case websocketEndpointSet(url: String?)
        case appcastEndpointSet(url: String?)
        case forceUpdateToSpecificVersionClicked(version: String)
        case deleteAllDeviceStorageClicked
      }

      case closeWindow
      case healthCheck(action: HealthCheckAction)
      case advanced(action: AdvancedAction)
      case gotoScreenClicked(screen: Screen)
      case stopFilterClicked
      case startFilterClicked
      case resumeFilterClicked
      case releaseChannelUpdated(channel: ReleaseChannel)
      case reinstallAppClicked
      case quitAppClicked
      case suspendFilterClicked(durationInSeconds: Int)
      case reconnectUserClicked
      case administrateOSUserAccountsClicked
      case checkForAppUpdatesClicked
      case setUserExemption(userId: uid_t, enabled: Bool)
      case inactiveAccountRecheckClicked
      case inactiveAccountDisconnectAppClicked
    }

    enum Delegate: Equatable, Sendable {
      case triggerAppUpdate
      case healthCheckFilterExtensionState(FilterExtensionState)
    }

    case closeWindow
    case setScreenRecordingPermissionOk(Bool)
    case setKeystrokeRecordingPermissionOk(Bool)
    case setNotificationsSetting(NotificationsSetting)
    case setMacOsUserType(Failable<MacOSUserType>)
    case setFilterStatus(State.HealthCheck.FilterStatus)
    case setExemptableUsers(Failable<[MacOSUser]>)
    case setExemptUserIds(Failable<[uid_t]>)
    case receivedRecentAppVersions([String: String])
    case webview(View)
    case delegate(Delegate)
    case healthCheckTimeout
  }

  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      .none
    }
  }

  struct RootReducer: FilterControlling, AdminAuthenticating {
    @Dependency(\.app) var app
    @Dependency(\.api) var api
    @Dependency(\.device) var device
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.filterExtension) var filter
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.monitoring) var monitoring
    @Dependency(\.date.now) var now
    @Dependency(\.security) var security
    @Dependency(\.storage) var storage
    @Dependency(\.updater) var updater
    @Dependency(\.websocket) var websocket
  }
}

private enum CancelId {
  case healthCheckTimeout
}

extension AdminWindowFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .menuBar(.administrateClicked):
      return adminAuthenticated(action)

    case .adminAuthenticated(.menuBar(.administrateClicked)):
      state.adminWindow.screen = .home
      state.adminWindow.windowOpen = true
      return .merge(
        .run { send in
          await send(.adminWindow(.setExemptableUsers(Failable {
            try await device.listExemptableUsers()
          })))
        },
        .run { send in
          await send(.adminWindow(.setExemptUserIds(Failable(
            result: await xpc.requestExemptUserIds()
          ))))
        },
        checkHealth(state: &state, action: action)
      )

    case .adminWindow(.webview(.healthCheck(.recheckClicked))):
      return checkHealth(state: &state, action: action)

    case .appUpdates(.delegate(.postUpdateFilterReplaceFailed)),
         .appUpdates(.delegate(.postUpdateFilterNotInstalled)):
      state.adminWindow.windowOpen = true
      state.adminWindow.screen = .healthCheck
      return checkHealth(state: &state, action: action)

    case .admin(.accountStatusResponse(.success(let status))):
      state.adminWindow.healthCheck.accountStatus = .ok(value: status)
      return state.adminWindow.healthCheck.checkCompletionEffect

    case .admin(.accountStatusResponse(.failure)):
      state.adminWindow.healthCheck.accountStatus = .error
      return state.adminWindow.healthCheck.checkCompletionEffect

    case .appUpdates(.latestVersionResponse(.success(let output))):
      state.adminWindow.healthCheck.latestAppVersion = .ok(value: output.semver)
      return state.adminWindow.healthCheck.checkCompletionEffect

    case .user(.refreshRules(.success, _)):
      return .run { send in
        // wait for feature reducer to send rules to filter
        try await mainQueue.sleep(for: .milliseconds(10))
        await recheckFilter(send)
      }

    case .adminWindow(let adminWindowAction):

      switch adminWindowAction {

      case .webview(.advanced(.forceUpdateToSpecificVersionClicked)):
        return .none // handled by UpdaterFeature, no auth needed

      case .webview(.advanced):
        return adminAuthenticated(action)

      case .webview(.healthCheck(.recheckClicked)):
        return .none // handled above

      case .webview(.inactiveAccountRecheckClicked),
           .webview(.inactiveAccountDisconnectAppClicked):
        return .none // handled by AdminFeature

      case .closeWindow,
           .webview(.closeWindow):
        state.adminWindow.windowOpen = false
        return .none

      case .webview(.gotoScreenClicked(.advanced)):
        return adminAuthenticated(action)

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

      case .webview(.healthCheck(.removeUserAdminPrivilegeClicked)),
           .webview(.administrateOSUserAccountsClicked):
        return .run { _ in
          await device.openSystemPrefs(.accounts)
        }

      case .webview(.healthCheck(.fixNotificationPermissionClicked)):
        return .run { _ in
          await device.openSystemPrefs(.notifications)
        }

      case .webview(.healthCheck(.repairOutOfDateFilterClicked)):
        return adminAuthenticated(action)

      case .webview(.healthCheck(.installFilterClicked)):
        state.adminWindow.healthCheck.filterStatus = .installing
        return .merge(
          .run { try await installFilter($0) },
          withTimeoutAfter(seconds: 60)
        )

      case .webview(.healthCheck(.repairFilterCommunicationClicked)):
        return adminAuthenticated(action)

      case .webview(.healthCheck(.zeroKeysRefreshRulesClicked)):
        state.adminWindow.healthCheck.filterStatus = nil
        return withTimeoutAfter(seconds: 10)

      case .webview(.healthCheck(.upgradeAppClicked)):
        return adminAuthenticated(action)

      case .webview(.checkForAppUpdatesClicked),
           .webview(.releaseChannelUpdated),
           .webview(.reinstallAppClicked):
        return .none // handled by AppUpdatesFeature

      case .webview(.quitAppClicked):
        return adminAuthenticated(action)

      case .webview(.stopFilterClicked):
        return adminAuthenticated(action)

      case .webview(.reconnectUserClicked):
        return adminAuthenticated(action)

      case .webview(.startFilterClicked),
           .webview(.resumeFilterClicked):
        return .none // handled by FilterFeature

      case .webview(.suspendFilterClicked):
        return adminAuthenticated(action)

      case .webview(.setUserExemption):
        return adminAuthenticated(action)

      case .setExemptUserIds(let result):
        state.adminWindow.exemptUserIds = result
        return .none

      case .setExemptableUsers(let usersResult):
        state.adminWindow.exemptableUsers = usersResult
        return .none

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

      case .receivedRecentAppVersions(let versions):
        state.adminWindow.recentAppVersions = versions
        return .none

      case .delegate:
        return .none
      }

    // admin authenticated
    case .adminAuthenticated(.adminWindow(let adminWindowAction)):
      switch adminWindowAction {
      case .webview(.healthCheck(.repairOutOfDateFilterClicked)):
        state.adminWindow.healthCheck.filterStatus = nil
        return .merge(
          .run { try await replaceFilter($0, retryOnce: true) },
          withTimeoutAfter(seconds: 5)
        )

      case .webview(.healthCheck(.repairFilterCommunicationClicked)):
        return .merge(
          .run { send in
            try await restartFilter(send)
            try await mainQueue.sleep(for: .milliseconds(10))
            if await xpc.notConnected() {
              try await replaceFilter(send, retryOnce: true)
            }
          },
          withTimeoutAfter(seconds: 5)
        )

      case .webview(.healthCheck(.upgradeAppClicked)):
        return .run {
          send in await send(.adminWindow(.delegate(.triggerAppUpdate)))
        }

      case .webview(.quitAppClicked):
        state.adminWindow.quitting = true
        return .run { _ in
          // give time for uploading keystrokes, websocket disconnect, etc
          try await mainQueue.sleep(for: .seconds(2))
          await app.quit()
        }

      case .webview(.stopFilterClicked):
        return .run { _ in _ = await filter.stop() }

      case .webview(.reconnectUserClicked):
        state.user = nil
        state.history.userConnection = .notConnected
        state.adminWindow.windowOpen = false
        state.menuBar.dropdownOpen = true
        return .run { [updated = state.persistent] _ in
          await api.clearUserToken()
          try await storage.savePersistentState(updated)
          _ = await xpc.disconnectUser()
        }

      case .webview(.setUserExemption(let userId, let enabled)):
        if case .ok(let exemptUserIds) = state.adminWindow.exemptUserIds {
          let updated = enabled
            ? exemptUserIds + [userId]
            : exemptUserIds.filter { $0 != userId }
          state.adminWindow.exemptUserIds = .ok(value: updated)
        } else if enabled {
          state.adminWindow.exemptUserIds = .ok(value: [userId])
        } else {
          state.adminWindow.exemptUserIds = .ok(value: [])
        }
        return .run { send in
          _ = await xpc.setUserExemption(userId, enabled)
        }

      case .webview(.advanced(let advancedAction)):
        switch advancedAction {
        case .appcastEndpointSet(let url):
          return .run { _ in await updater.updateEndpointOverride(url) }
        case .pairqlEndpointSet(let url):
          return .run { _ in await api.updateEndpointOverride(url) }
        case .websocketEndpointSet:
          return .none // handled by WebsocketFeature
        case .forceUpdateToSpecificVersionClicked:
          return .none // handled by UpdaterFeature
        case .deleteAllDeviceStorageClicked:
          return .run { _ in
            await storage.deleteAll()
            _ = await xpc.sendDeleteAllStoredState()
          }
        }

      case .webview(.gotoScreenClicked(.advanced)):
        state.adminWindow.screen = .advanced
        return .run { send in
          if let versions = try? await api.recentAppVersions() {
            await send(.adminWindow(.receivedRecentAppVersions(versions)))
          }
        }

      default:
        return .none
      }

    default:
      return .none
    }
  }

  func checkHealth(state: inout State, action: Action) -> Effect<Action> {
    state.adminWindow.healthCheck = .init()
    let keyloggingEnabled = state.user?.keyloggingEnabled == true
    let screenRecordingEnabled = state.user?.screenshotsEnabled == true
    let releaseChannel = state.appUpdates.releaseChannel
    let currentInstalledVersion = state.appUpdates.installedVersion

    let main = Effect<Action>.run { send in
      try await mainQueue.sleep(for: .seconds(1))

      async let accountStatus = TaskResult {
        try await api.getAdminAccountStatus()
      }

      async let latestAppVersionOutput = TaskResult {
        try await api.latestAppVersion(.init(
          releaseChannel: releaseChannel,
          currentVersion: currentInstalledVersion
        ))
      }

      await send(.admin(.accountStatusResponse(accountStatus)))
      await send(.appUpdates(.latestVersionResponse(latestAppVersionOutput)))

      await send(.adminWindow(.setKeystrokeRecordingPermissionOk(
        keyloggingEnabled ? await monitoring.keystrokeRecordingPermissionGranted() : true
      )))

      await send(.adminWindow(.setScreenRecordingPermissionOk(
        screenRecordingEnabled ? await monitoring.screenRecordingPermissionGranted() : true
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
  }

  func afterFilterChange(_ send: Send<Action>) async {
    await recheckFilter(send)
  }

  func withTimeoutAfter(seconds: Int) -> Effect<Action> {
    .run { send in
      try await mainQueue.sleep(for: .seconds(seconds))
      await send(.adminWindow(.healthCheckTimeout))
    }.cancellable(id: CancelId.healthCheckTimeout, cancelInFlight: true)
  }

  func recheckFilter(_ send: Send<Action>) async {
    let filterState = await filter.state()
    await send(.adminWindow(.delegate(.healthCheckFilterExtensionState(filterState))))
    switch filterState {
    case .notInstalled:
      await send(.adminWindow(.setFilterStatus(.notInstalled)))
      return
    case .errorLoadingConfig, .unknown:
      await send(.adminWindow(.setFilterStatus(.unexpected)))
      return
    case .installedAndRunning, .installedButNotRunning:
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
}

extension AdminWindowFeature.State {}

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
    filterState = .init(rootState)
    userName = rootState.user?.name ?? ""
    screenshotMonitoringEnabled = rootState.user?.screenshotsEnabled ?? false
    keystrokeMonitoringEnabled = rootState.user?.keyloggingEnabled ?? false
    installedAppVersion = app.installedVersion() ?? "0.0.0"
    releaseChannel = rootState.appUpdates.releaseChannel
    quitting = featureState.quitting

    // TODO: this whole feature is not great
    // @see https://github.com/gertrude-app/project/issues/156
    if screen == .advanced {
      advanced = .init(
        pairqlEndpointOverride: ApiClient.endpointOverride()?.absoluteString,
        pairqlEndpointDefault: ApiClient.defaultEndpoint().absoluteString,
        websocketEndpointOverride: WebSocketClient.endpointOverride()?.absoluteString,
        websocketEndpointDefault: WebSocketClient.defaultEndpoint().absoluteString,
        appcastEndpointOverride: UpdaterClient.endpointOverride()?.absoluteString,
        appcastEndpointDefault: UpdaterClient.defaultEndpoint().absoluteString,
        appVersions: featureState.recentAppVersions
      )
    }

    switch (featureState.exemptableUsers, featureState.exemptUserIds) {
    case (.ok(let users), .ok(let userIds)):
      exemptableUsers = .ok(value: users.map {
        ExemptableUser(
          id: $0.id,
          name: $0.name,
          isAdmin: $0.type == .admin,
          isExempt: userIds.contains($0.id)
        )
      })
    case (.error, _), (_, .error):
      exemptableUsers = .error
    default:
      exemptableUsers = nil
    }
  }
}

extension AdminWindowFeature.Reducer {
  typealias State = AdminWindowFeature.State
  typealias Action = AdminWindowFeature.Action
}
