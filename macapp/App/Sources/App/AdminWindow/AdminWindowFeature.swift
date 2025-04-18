import ClientInterfaces
import ComposableArchitecture
import Core
import Foundation
import Gertie
import TaggedTime

struct AdminWindowFeature: Feature {
  enum Screen: String, Equatable, Codable {
    case healthCheck
    case actions
    case exemptUsers
    case advanced
  }

  struct State: Equatable {
    struct HealthCheck: Equatable, Encodable {
      enum FilterStatus: Equatable, Codable {
        case installing
        case installTimeout
        case notInstalled
        case disabled
        case unexpected
        case communicationBroken(repairing: Bool)
        case installed(version: String, numUserKeys: Int)
      }

      var latestAppVersion: Failable<String>?
      var filterStatus: FilterStatus?
      var accountStatus: Failable<AdminAccountStatus>?
      var screenRecordingPermissionOk: Bool?
      var keystrokeRecordingPermissionOk: Bool?
      var fullDiskAccessPermissionOk: Bool?
      var macOsUserType: Failable<MacOSUserType>?
      var notificationsSetting: NotificationsSetting?
    }

    var windowOpen = false
    var screen: Screen = .healthCheck
    var healthCheck: HealthCheck = .init()
    var quitting = false
    var exemptableUsers: Failable<[MacOSUser]>?
    var exemptUserIds: Failable<[uid_t]>?
    var recentAppVersions: [String: String]?

    struct View: Equatable, Encodable {
      var windowOpen = false
      var screen: AdminWindowFeature.Screen
      var healthCheck: HealthCheck
      var filterState: FilterState.WithRelativeTimes
      var user: User?
      var availableAppUpdate: AvailableAppUpdate?
      var installedAppVersion: String
      var releaseChannel: ReleaseChannel
      var quitting: Bool

      struct AvailableAppUpdate: Equatable, Encodable {
        var semver: String
        var required: Bool
      }

      struct User: Equatable, Codable {
        var name: String
        var screenshotMonitoringEnabled: Bool
        var keystrokeMonitoringEnabled: Bool
      }

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
        var webviewDebugging: Bool
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
        case enableFilterClicked
        case repairFilterCommunicationClicked
        case repairOutOfDateFilterClicked
        case fixScreenRecordingPermissionClicked
        case fixKeystrokeRecordingPermissionClicked
        case fixFullDiskAccessPermissionClicked
        case removeUserAdminPrivilegeClicked
        case fixNotificationPermissionClicked
        case zeroKeysRefreshRulesClicked
      }

      enum AdvancedAction: Equatable, Sendable, Codable {
        case pairqlEndpointSet(url: String?)
        case websocketEndpointSet(url: String?)
        case appcastEndpointSet(url: String?)
        case setWebviewDebugging(enabled: Bool)
        case forceUpdateToSpecificVersionClicked(version: String)
        case deleteAllDeviceStorageClicked
      }

      case closeWindow
      case healthCheck(action: HealthCheckAction)
      case advanced(action: AdvancedAction)
      case gotoScreenClicked(screen: Screen)
      case confirmStopFilterClicked
      case confirmQuitAppClicked
      case disconnectUserClicked
      case administrateOSUserAccountsClicked
      case updateAppNowClicked
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
    case setFullDiskAccessPermissionOk(Bool)
    case setNotificationsSetting(NotificationsSetting)
    case setMacOsUserType(Failable<MacOSUserType>)
    case setFilterStatus(State.HealthCheck.FilterStatus)
    case setExemptionData(Failable<[MacOSUser]>, Failable<FilterUserTypes>)
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

  struct RootReducer: RootReducing, FilterControlling, AdminAuthenticating {
    typealias State = AppReducer.State
    typealias Action = AppReducer.Action
    @Dependency(\.api) var api
    @Dependency(\.app) var app
    @Dependency(\.device) var device
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.filterExtension) var filter
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.monitoring) var monitoring
    @Dependency(\.network) var network
    @Dependency(\.security) var security
    @Dependency(\.storage) var storage
    @Dependency(\.updater) var updater
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

    case .adminAuthed(.menuBar(.administrateClicked)):
      state.adminWindow.screen = .healthCheck
      state.adminWindow.windowOpen = true
      return .merge(
        .exec { send in
          await send(.adminWindow(.setExemptionData(
            Failable { try await self.device.nonCurrentUsers() },
            Failable(result: self.xpc.requestUserTypes())
          )))
        },
        self.checkHealth(state: &state, action: action)
      )

    case .adminWindow(.webview(.healthCheck(.recheckClicked))):
      return self.checkHealth(state: &state, action: action)

    case .appUpdates(.delegate(.postUpdateFilterReplaceFailed)),
         .appUpdates(.delegate(.postUpdateFilterNotInstalled)):
      state.adminWindow.windowOpen = true
      state.adminWindow.screen = .healthCheck
      return self.checkHealth(state: &state, action: action)

    case .checkIn(.success(result: let result), _) where state.adminWindow.windowOpen:
      state.adminWindow.healthCheck.accountStatus = .ok(value: result.adminAccountStatus)
      state.adminWindow.healthCheck.latestAppVersion = .ok(value: result.latestRelease.semver)
      return .merge(
        state.adminWindow.healthCheck.checkCompletionEffect,
        .exec { send in
          // wait for user feature reducer to send rules to filter
          try await self.mainQueue.sleep(for: .milliseconds(10))
          await self.recheckFilter(send)
        }
      )

    case .checkIn(.failure, _) where state.adminWindow.windowOpen:
      state.adminWindow.healthCheck.accountStatus = .error
      state.adminWindow.healthCheck.latestAppVersion = .error
      return state.adminWindow.healthCheck.checkCompletionEffect

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

      case .webview(.gotoScreenClicked(.healthCheck)):
        let prev = state.adminWindow.screen
        state.adminWindow.screen = .healthCheck
        return prev == .healthCheck ? .none : self.checkHealth(state: &state, action: action)

      case .webview(.gotoScreenClicked(let screen)):
        state.adminWindow.screen = screen
        return .none

      case .webview(.healthCheck(.fixKeystrokeRecordingPermissionClicked)):
        return .exec { _ in
          await self.device.openSystemPrefs(.security(.accessibility))
        }

      case .webview(.healthCheck(.fixFullDiskAccessPermissionClicked)):
        return .exec { _ in
          await device.openSystemPrefs(.security(.fullDiskAccess))
        }

      case .webview(.healthCheck(.fixScreenRecordingPermissionClicked)):
        return .exec { _ in
          await self.device.openSystemPrefs(.security(.screenRecording))
        }

      case .webview(.healthCheck(.removeUserAdminPrivilegeClicked)),
           .webview(.administrateOSUserAccountsClicked):
        return .exec { _ in
          await self.device.openSystemPrefs(.accounts)
        }

      case .webview(.healthCheck(.fixNotificationPermissionClicked)):
        return .exec { _ in
          await self.device.requestNotificationAuthorization()
          await self.device.openSystemPrefs(.notifications)
        }

      case .webview(.healthCheck(.repairOutOfDateFilterClicked)):
        return adminAuthenticated(action)

      case .webview(.healthCheck(.enableFilterClicked)):
        state.adminWindow.healthCheck.filterStatus = nil
        return .merge(
          .exec { try await self.startFilter($0) },
          self.withTimeoutAfter(seconds: 3)
        )

      case .webview(.healthCheck(.installFilterClicked)):
        state.adminWindow.healthCheck.filterStatus = .installing
        return .merge(
          .exec { try await self.installFilter($0) },
          self.withTimeoutAfter(seconds: 20)
        )

      case .webview(.healthCheck(.repairFilterCommunicationClicked)):
        return adminAuthenticated(action)

      case .webview(.healthCheck(.zeroKeysRefreshRulesClicked)):
        state.adminWindow.healthCheck.filterStatus = nil
        return self.withTimeoutAfter(seconds: 10)

      case .webview(.healthCheck(.upgradeAppClicked)):
        return adminAuthenticated(action)

      case .webview(.updateAppNowClicked):
        return .none // handled by AppUpdatesFeature

      case .webview(.confirmQuitAppClicked):
        return adminAuthenticated(action)

      case .webview(.confirmStopFilterClicked):
        return adminAuthenticated(action)

      case .webview(.disconnectUserClicked):
        return adminAuthenticated(action)

      case .webview(.setUserExemption):
        return adminAuthenticated(action)

      case .setExemptionData(let exemptableUsers, let filterUsersResult):
        state.adminWindow.exemptableUsers = exemptableUsers
        switch filterUsersResult {
        case .ok(let filterUsers):
          state.adminWindow.exemptUserIds = .ok(value: filterUsers.exempt)
        case .error(let err):
          state.adminWindow.exemptUserIds = .error(message: err)
        }
        if case .ok(let exemptable) = exemptableUsers {
          state.adminWindow.exemptableUsers = .ok(value: exemptable)
        }
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

      case .setFullDiskAccessPermissionOk(let granted):
        state.adminWindow.healthCheck.fullDiskAccessPermissionOk = granted
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
    case .adminAuthed(.adminWindow(let adminWindowAction)):
      switch adminWindowAction {
      case .webview(.healthCheck(.repairOutOfDateFilterClicked)):
        state.adminWindow.healthCheck.filterStatus = nil
        return .merge(
          .exec { try await replaceFilter($0) },
          self.withTimeoutAfter(seconds: 10)
        )

      case .webview(.healthCheck(.repairFilterCommunicationClicked)):
        state.adminWindow.healthCheck.filterStatus = nil
        return .merge(
          .exec { send in
            try await restartFilter(send)
            try await self.mainQueue.sleep(for: .milliseconds(10))
            if await self.xpc.notConnected() {
              try await replaceFilter(send)
            }
          },
          self.withTimeoutAfter(seconds: 10)
        )

      case .webview(.healthCheck(.upgradeAppClicked)):
        return .exec {
          send in await send(.adminWindow(.delegate(.triggerAppUpdate)))
        }

      case .webview(.confirmQuitAppClicked):
        state.adminWindow.quitting = true
        return .exec { _ in
          await self.api.securityEvent(.appQuit)
          // give time for uploading keystrokes, websocket disconnect, etc
          try await self.mainQueue.sleep(for: .seconds(2))
          await self.app.quit()
        }

      case .webview(.disconnectUserClicked):
        // handled by UserConnectionFeature
        return .none

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
        return .exec { send in
          if enabled {
            await self.api.securityEvent(.macosUserExempted, "userId: \(userId)")
          }
          _ = await self.xpc.setUserExemption(userId, enabled)
        }

      case .webview(.advanced(let advancedAction)):
        switch advancedAction {
        case .appcastEndpointSet(let url):
          return .exec { _ in await self.updater.updateEndpointOverride(url) }
        case .pairqlEndpointSet(let url):
          return .exec { _ in await self.api.updateEndpointOverride(url) }
        case .setWebviewDebugging(let enabled):
          return .exec { _ in
            UserDefaults.standard.set(enabled, forKey: "allowWebviewDebugging")
          }
        case .websocketEndpointSet:
          return .none // handled by WebsocketFeature
        case .forceUpdateToSpecificVersionClicked:
          return .none // handled by UpdaterFeature
        case .deleteAllDeviceStorageClicked:
          return .exec { _ in
            await self.storage.deleteAll()
            _ = await self.xpc.sendDeleteAllStoredState()
          }
        }

      case .webview(.gotoScreenClicked(.advanced)):
        state.adminWindow.screen = .advanced
        return .exec { send in
          await self.api.securityEvent(.advancedSettingsOpened)
          guard self.network.isConnected() else { return }
          if let versions = try? await self.api.recentAppVersions() {
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
    state.adminWindow.healthCheck = .init() // put all checks into checking state
    let filterVersion = state.filter.version
    let keyloggingEnabled = state.user.data?.keyloggingEnabled == true
    let screenRecordingEnabled = state.user.data?.screenshotsEnabled == true

    let main = Effect<Action>.exec { send in
      try await self.mainQueue.sleep(for: .seconds(1))

      await send(.checkIn(
        result: self.network.isConnected()
          ? TaskResult { try await self.api.appCheckIn(filterVersion) }
          : .failure(NetworkClient.NotConnected()),
        reason: .healthCheck
      ))

      await send(.adminWindow(.setKeystrokeRecordingPermissionOk(
        keyloggingEnabled ? self.monitoring.keystrokeRecordingPermissionGranted() : true
      )))

      await send(.adminWindow(.setScreenRecordingPermissionOk(
        screenRecordingEnabled ? self.monitoring.screenRecordingPermissionGranted() : true
      )))

      await send(.adminWindow(.setFullDiskAccessPermissionOk(
        self.app.hasFullDiskAccess()
      )))

      await send(.adminWindow(.setNotificationsSetting(
        self.device.notificationsSetting()
      )))

      await send(.adminWindow(.setMacOsUserType(
        .init { try await self.device.currentMacOsUserType() }
      )))

      await self.recheckFilter(send)

      try await self.mainQueue.sleep(for: .seconds(10))

      await send(.adminWindow(.healthCheckTimeout))
    }.cancellable(id: CancelId.healthCheckTimeout, cancelInFlight: true)

    return .merge(
      main,
      action == .adminWindow(.webview(.healthCheck(action: .recheckClicked)))
        ? .cancel(id: CancelId.healthCheckTimeout) : .none
    )
  }

  func afterFilterChange(_ send: Send<Action>, repairing: Bool = false) async {
    await self.recheckFilter(send, repairing: repairing)
  }

  func withTimeoutAfter(seconds: Int) -> Effect<Action> {
    .exec { send in
      try await self.mainQueue.sleep(for: .seconds(seconds))
      await send(.adminWindow(.healthCheckTimeout))
    }.cancellable(id: CancelId.healthCheckTimeout, cancelInFlight: true)
  }

  private func recheckFilter(_ send: Send<Action>, repairing: Bool = false) async {
    let filterState = await self.filter.state()
    await send(.adminWindow(.delegate(.healthCheckFilterExtensionState(filterState))))
    switch filterState {
    case .notInstalled:
      await send(.adminWindow(.setFilterStatus(.notInstalled)))
      return
    case .errorLoadingConfig, .unknown:
      await send(.adminWindow(.setFilterStatus(.unexpected)))
      return
    case .installedAndRunning:
      switch await self.xpc.requestAck() {
      case .success(let ack) where ack.userId == getuid():
        await send(.adminWindow(.setFilterStatus(
          .installed(version: ack.version, numUserKeys: ack.numUserKeys)
        )))
      case .success(let ack):
        await send(.adminWindow(.setFilterStatus(
          .installed(version: ack.version, numUserKeys: 0)
        )))
      case .failure:
        await send(.adminWindow(.setFilterStatus(.communicationBroken(repairing: repairing))))
      }
    case .installedButNotRunning:
      switch await self.xpc.requestAck() {
      case .success(let ack) where ack.userId == getuid():
        await send(.adminWindow(.setFilterStatus(
          .installed(version: ack.version, numUserKeys: ack.numUserKeys)
        )))
      case .success(let ack):
        await send(.adminWindow(.setFilterStatus(
          .installed(version: ack.version, numUserKeys: 0)
        )))
      case .failure:
        await send(.adminWindow(.setFilterStatus(.disabled)))
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
    self.isComplete ? Effect.cancel(id: CancelId.healthCheckTimeout) : .none
  }
}

extension AdminWindowFeature.State.View {
  init(rootState: AppReducer.State) {
    @Dependency(\.app) var app
    let featureState = rootState.adminWindow
    let installedVersion = app.installedVersion() ?? "0.0.0"

    self.windowOpen = featureState.windowOpen
    self.screen = featureState.screen
    self.healthCheck = featureState.healthCheck
    self.filterState = .init(from: rootState)
    self.user = rootState.user.data.map { user in .init(
      name: user.name,
      screenshotMonitoringEnabled: user.screenshotsEnabled,
      keystrokeMonitoringEnabled: user.keyloggingEnabled
    ) }
    self.installedAppVersion = installedVersion
    self.releaseChannel = rootState.appUpdates.releaseChannel
    self.quitting = featureState.quitting

    if let latest = rootState.appUpdates.latestVersion, latest.semver > installedVersion {
      availableAppUpdate = .init(
        semver: latest.semver,
        required: latest.pace.map { pace in
          @Dependency(\.date.now) var now
          return now > pace.nagOn
        } ?? false
      )
    }

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
        appVersions: featureState.recentAppVersions,
        webviewDebugging: UserDefaults.standard.bool(forKey: "allowWebviewDebugging")
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
