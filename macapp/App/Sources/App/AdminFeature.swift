import ComposableArchitecture
import Gertie

struct AdminFeature: Feature {
  struct State: Equatable {
    var accountStatus: AdminAccountStatus = .active
  }

  enum Action: Equatable, Sendable {
    case accountStatusResponse(TaskResult<AdminAccountStatus>)
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.api) var api

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {

      case .accountStatusResponse(.success(let status)):
        state.accountStatus = status
        return .run { _ in
          await api.setAccountActive(status == .active)
        }

      case .accountStatusResponse(.failure):
        return .none
      }
    }
  }

  struct RootReducer: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.app) var app
    @Dependency(\.device) var device
    @Dependency(\.network) var network
    @Dependency(\.security) var security
    @Dependency(\.storage) var storage
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.filterExtension) var filter
  }
}

extension AdminFeature.RootReducer: RootReducing, AdminAuthenticating {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .heartbeat(.everySixHours):
      return .run { send in
        guard network.isConnected() else { return }
        await send(.admin(.accountStatusResponse(TaskResult {
          try await api.getAdminAccountStatus()
        })))
      }

    case .adminWindow(.webview(.inactiveAccountRecheckClicked)),
         .blockedRequests(.webview(.inactiveAccountRecheckClicked)),
         .requestSuspension(.webview(.inactiveAccountRecheckClicked)):
      return .run { send in
        guard network.isConnected() else {
          await device.notifyNoInternet()
          return
        }
        await send(.admin(.accountStatusResponse(TaskResult {
          try await api.getAdminAccountStatus()
        })))
      }

    case .adminWindow(.webview(.inactiveAccountDisconnectAppClicked)),
         .blockedRequests(.webview(.inactiveAccountDisconnectAppClicked)),
         .requestSuspension(.webview(.inactiveAccountDisconnectAppClicked)):
      return adminAuthenticated(action)

    case .adminAuthenticated(.adminWindow(.webview(.inactiveAccountDisconnectAppClicked))),
         .adminAuthenticated(.blockedRequests(.webview(.inactiveAccountDisconnectAppClicked))),
         .adminAuthenticated(.requestSuspension(.webview(.inactiveAccountDisconnectAppClicked))):
      state.user = nil
      state.history.userConnection = .notConnected
      state.filter.extension = .notInstalled
      state.filter.currentSuspensionExpiration = nil
      return .run { _ in
        await app.disableLaunchAtLogin()
        await api.clearUserToken()
        await storage.deleteAll()
        _ = await xpc.sendDeleteAllStoredState()
        _ = await filter.uninstall()
        await app.quit()
      }

    default:
      return .none
    }
  }
}
