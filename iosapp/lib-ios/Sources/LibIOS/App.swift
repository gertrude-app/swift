import ComposableArchitecture
import Foundation

@Reducer
public struct AppReducer {
  @ObservableState
  public struct State: Equatable {
    public var appState: AppState
    public var firstLaunch: Date?

    public init(appState: AppState = .launching) {
      self.appState = appState
    }
  }

  @ObservationIgnored
  @Dependency(\.api) var api
  @ObservationIgnored
  @Dependency(\.system) var system
  @ObservationIgnored
  @Dependency(\.storage) var storage
  @ObservationIgnored
  @Dependency(\.date.now) var now

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
    case setFirstLaunch(Date)
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {

      case .appLaunched:
        return .run { send in
          await send(.setRunning(await self.system.filterRunning()))
          if let firstLaunch = self.storage.object(forKey: .launchDateStorageKey) as? Date {
            await send(.setFirstLaunch(firstLaunch))
          } else {
            let now = self.now
            self.storage.set(now, forKey: .launchDateStorageKey)
            await send(.setFirstLaunch(now))
            await self.api.logEvent("dcd721aa", "first launch")
          }
        }

      case .setRunning(true):
        state.appState = .running
        return .none

      case .setFirstLaunch(let date):
        state.firstLaunch = date
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
          switch await self.system.requestAuthorization() {
          case .success:
            await send(.authorizationSucceeded)
            await self.api.logEvent("d317c73c", "authorization succeeded")
          case .failure(let reason):
            await send(.authorizationFailed(reason))
            await self.system.cleanupForRetry()
            await self.api.logEvent("d9dfd021", "authorization failed: \(reason)")
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
          switch await self.system.installFilter() {
          case .success:
            await send(.installSucceeded)
            await self.api.logEvent("101c91ea", "filter install success")
          case .failure(let error):
            await send(.installFailed(error))
            await self.system.cleanupForRetry()
            await self.api.logEvent("739c08c6", "filter install failed: \(error)")
          }
        }

      case .installFailed(let error):
        state.appState = .installFailed(error)
        return .none

      case .installFailedTryAgainTapped:
        state.appState = .welcome
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
