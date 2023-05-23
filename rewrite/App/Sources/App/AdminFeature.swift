import ComposableArchitecture
import Shared

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
        await send(.admin(.accountStatusResponse(TaskResult {
          try await api.getAdminAccountStatus()
        })))
      }

    case .adminWindow(.webview(.inactiveAccountRecheckClicked)),
         .blockedRequests(.webview(.inactiveAccountRecheckClicked)),
         .requestSuspension(.webview(.inactiveAccountRecheckClicked)):
      return .run { send in
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
        // TODO: remove launch at login
        await api.clearUserToken()
        await storage.deleteAllPersistentState()
        _ = await xpc.sendPrepareForUninstall()
        _ = await filter.uninstall()
        await app.quit()
      }

    default:
      return .none
    }
  }
}
