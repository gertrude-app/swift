import ComposableArchitecture
import Gertie

struct AdminFeature: Feature {
  struct State: Equatable {
    var accountStatus: AdminAccountStatus = .active
  }

  typealias Action = Never

  struct RootReducer: Sendable {
    typealias Action = AppReducer.Action
    typealias State = AppReducer.State
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
    case .adminWindow(.webview(.inactiveAccountDisconnectAppClicked)),
         .blockedRequests(.webview(.inactiveAccountDisconnectAppClicked)),
         .requestSuspension(.webview(.inactiveAccountDisconnectAppClicked)),
         .requestSuspension(.webview(.noFilterCommunicationAdministrateClicked)),
         .blockedRequests(.webview(.noFilterCommunicationAdministrateClicked)):
      return adminAuthenticated(action)

    case .adminAuthed(.adminWindow(.webview(.inactiveAccountDisconnectAppClicked))),
         .adminAuthed(.blockedRequests(.webview(.inactiveAccountDisconnectAppClicked))),
         .adminAuthed(.requestSuspension(.webview(.inactiveAccountDisconnectAppClicked))):
      state.user = .init()
      state.history.userConnection = .notConnected
      state.filter.extension = .notInstalled
      state.filter.currentSuspensionExpiration = nil
      return .exec { _ in
        await app.disableLaunchAtLogin()
        await api.clearUserToken()
        await storage.deleteAll()
        _ = await xpc.sendDeleteAllStoredState()
        _ = await filter.uninstall()
        await app.quit()
      }

    case .adminAuthed(.blockedRequests(.webview(.noFilterCommunicationAdministrateClicked))),
         .adminAuthed(.requestSuspension(.webview(.noFilterCommunicationAdministrateClicked))):
      state.blockedRequests.windowOpen = false
      state.requestSuspension.windowOpen = false
      state.adminWindow.windowOpen = true
      state.adminWindow.screen = .healthCheck
      return .exec { send in
        // we've already authed the admin, this kicks off a full health check
        await send(.adminAuthed(.menuBar(.administrateClicked)))
      }

    default:
      return .none
    }
  }
}
