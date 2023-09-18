import ComposableArchitecture
import Foundation

struct OnboardingFeature: Feature {
  struct State: Equatable, Encodable, Sendable {
    struct MacUser: Equatable, Encodable {
      var id: uid_t
      var name: String
      var isAdmin: Bool

      enum RemediationStep: String, Equatable, Encodable {
        case create
        case `switch`
        case demote
        case choose
      }
    }

    var windowOpen = false
    var step: Step = .welcome
    var userRemediationStep: MacUser.RemediationStep?
    var currentUser: MacUser?
    var connectChildRequest: PayloadRequestState<String, String> = .idle
    var users: [MacUser] = []
  }

  enum Action: Equatable, Sendable {
    enum Webview: Equatable, Sendable {
      case primaryBtnClicked
      case secondaryBtnClicked
      case chooseSwitchToNonAdminUserClicked
      case chooseCreateNonAdminClicked
      case chooseDemoteAdminClicked
      case connectChildSubmitted(Int)
    }

    enum Delegate: Equatable, Sendable {
      case saveCurrentStep(State.Step?)
    }

    case webview(Webview)
    case delegate(Delegate)
    case receivedUserData(uid_t, [MacOSUser])
    case connectUser(TaskResult<UserData>)
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.api) var api
    @Dependency(\.app) var app
    @Dependency(\.device) var device
    @Dependency(\.storage) var storage

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      let step = state.step
      let userIsAdmin = state.currentUser?.isAdmin != false
      switch action {

      case .receivedUserData(let currentUserId, let users):
        state.users = users.map(State.MacUser.init)
        state.currentUser = state.users.first(where: { $0.id == currentUserId })
        return .none

      case .webview(.primaryBtnClicked) where step == .welcome:
        state.step = .confirmGertrudeAccount
        return .exec { send in
          await send(.receivedUserData(device.currentUserId(), try await device.listMacOSUsers()))
        }

      case .webview(.primaryBtnClicked) where step == .confirmGertrudeAccount:
        state.step = .macosUserAccountType
        return .none

      case .webview(.secondaryBtnClicked) where step == .confirmGertrudeAccount:
        state.step = .noGertrudeAccount
        return .none

      case .webview(.secondaryBtnClicked) where step == .noGertrudeAccount:
        return .exec { _ in
          await storage.deleteAll()
          await app.quit()
        }

      case .webview(.primaryBtnClicked) where step == .macosUserAccountType && !userIsAdmin:
        state.step = .getChildConnectionCode
        return .none

      // they choose to ignore the warning about user type and proceed
      case .webview(.secondaryBtnClicked) where step == .macosUserAccountType && userIsAdmin:
        state.step = .getChildConnectionCode
        return .none

      // they click "show me how to fix" on the BAD mac os user landing page
      case .webview(.primaryBtnClicked) where step == .macosUserAccountType && userIsAdmin:
        state.userRemediationStep = state.users.count == 1 ? .create : .choose
        return .send(.delegate(.saveCurrentStep(.macosUserAccountType)))

      case .webview(.chooseDemoteAdminClicked):
        state.userRemediationStep = .demote
        return .none

      case .webview(.chooseCreateNonAdminClicked):
        state.userRemediationStep = .create
        return .none

      case .webview(.chooseSwitchToNonAdminUserClicked):
        state.userRemediationStep = .switch
        return .none

      case .webview(.primaryBtnClicked) where step == .getChildConnectionCode:
        state.step = .connectChild
        return .none

      case .webview(.connectChildSubmitted(let code)):
        state.connectChildRequest = .ongoing
        return .exec { send in
          await send(.connectUser((TaskResult {
            try await api.connectUser(.init(code: code, device: device, app: app))
          })))
        }

      case .connectUser(.success(let user)):
        state.connectChildRequest = .succeeded(payload: user.name)
        return .none

      case .connectUser(.failure(let error)):
        state.connectChildRequest = .failed(error: error.userMessage())
        return .none

      case .webview(.primaryBtnClicked)
        where step == .connectChild && state.connectChildRequest.isFailed:
        state.connectChildRequest = .idle
        state.step = .getChildConnectionCode
        return .none

      case .webview(.secondaryBtnClicked)
        where step == .connectChild && state.connectChildRequest.isFailed:
        return .exec { _ in
          await device.openWebUrl(.contact)
        }

      case .webview(.primaryBtnClicked)
        where step == .connectChild && state.connectChildRequest.isSucceeded:
        state.step = .allowNotifications_start
        return .none

      case .webview(.primaryBtnClicked):
        return .none

      case .webview(.secondaryBtnClicked):
        return .none

      case .delegate:
        return .none
      }
    }
  }

  struct RootReducer: RootReducing {
    // todo
  }
}

extension OnboardingFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Self.Action> {
    .none
  }
}

extension OnboardingFeature.State {
  enum Step: Equatable, Codable {
    case welcome
    case confirmGertrudeAccount
    case noGertrudeAccount
    case macosUserAccountType
    case getChildConnectionCode
    case connectChild
    case allowNotifications_start
    case allowNotifications_grant
    case allowScreenshots_required
    case allowScreenshots_openSysSettings
    case allowScreenshots_grantAndRestart
    case allowScreenshots_success
    case allowKeylogging_required
    case allowKeylogging_openSysSettings
    case allowKeylogging_grant
    case allowKeylogging_failed
    case allowKeylogging_success
    case installSysExt_explain
    case installSysExt_start
    case installSysExt_allowInstall
    case installSysExt_allowFiltering
    case installSysExt_failed
    case installSysExt_success
    case locateMenuBarIcon
    case viewHealthCheck
    case howToUseGertrude
    case finish
  }
}

extension OnboardingFeature.State.MacUser {
  init(_ user: MacOSUser) {
    id = user.id
    name = user.name
    isAdmin = user.type == .admin
  }
}
