import ComposableArchitecture

@Reducer
public struct AppReducer {
  @ObservableState
  public struct State: Equatable {
    public var appState: AppState

    public init(appState: AppState = .launching) {
      self.appState = appState
    }
  }

  // TODO: figure out why i can't use a root store enum
  public enum AppState: Equatable {
    case launching
    case welcome
    case prereqs
    case authorizing
    case authorizationFailed(AuthFailureReason)
    case authorized
    case installFailed(FilterInstallError)
    case postInstall
    case running
  }

  public enum Action: Equatable {
    case appLaunched
    case welcomeNextTapped
    case startAuthorizationTapped
    case authorizationFailed(AuthFailureReason)
    case authorizationSucceeded
    case authorizationFailedTryAgainTapped
    case installFailed(FilterInstallError)
    case installFailedTryAgainTapped
    case installSucceeded
    case installFilterTapped
    case postInstallOkTapped
    case setRunning(Bool)
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {

      case .appLaunched:
        return .run { send in
          await send(.setRunning(await isRunning()))
        }

      case .setRunning(true):
        state.appState = .running
        return .none

      case .setRunning(false):
        state.appState = .welcome
        return .none

      case .welcomeNextTapped:
        state.appState = .prereqs
        return .none

      case .startAuthorizationTapped:
        state.appState = .authorizing
        return .run { send in
          switch await requestAuthorization() {
          case .success:
            await send(.authorizationSucceeded)
          case .failure(let reason):
            await send(.authorizationFailed(reason))
          }
        }

      case .authorizationSucceeded:
        state.appState = .authorized
        return .none

      case .authorizationFailed(let reason):
        state.appState = .authorizationFailed(reason)
        return .none

      case .authorizationFailedTryAgainTapped:
        state.appState = .welcome
        return .none

      case .installFilterTapped:
        return .run { send in
          switch await saveConfiguration() {
          case .success:
            await send(.installSucceeded)
          case .failure(let error):
            await send(.installFailed(error))
          }
        }

      case .installFailed(let error):
        state.appState = .installFailed(error)
        return .none

      case .installFailedTryAgainTapped:
        // TODO: clean up for retry
        return .none

      case .installSucceeded:
        state.appState = .postInstall
        return .none

      case .postInstallOkTapped:
        state.appState = .running
        return .none
      }
    }
  }

  public init() {}
}
