import ComposableArchitecture
import Foundation
import LibClients
import LibCore

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
  @Dependency(\.systemExtension) var systemExtension
  @ObservationIgnored
  @Dependency(\.storage) var storage
  @ObservationIgnored
  @Dependency(\.filter) var filter
  @ObservationIgnored
  @Dependency(\.device) var device
  @ObservationIgnored
  @Dependency(\.date.now) var now
  @ObservationIgnored
  @Dependency(\.locale) var locale
  @ObservationIgnored
  @Dependency(\.suspendingClock) var clock

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
    case running(showVendorId: Bool)
  }

  public enum Action: Equatable {
    case appLaunched
    case welcomeNextTapped
    case startAuthorizationTapped
    case authorizationFailed(AuthFailureReason)
    case authorizationSucceeded
    case authorizationFailedTryAgainTapped
    case authorizationFailedReviewRequirementsTapped
    case installFailed(FilterInstallError)
    case installFailedTryAgainTapped
    case installSucceeded
    case installFilterTapped
    case postInstallOkTapped
    case setRunning(Bool)
    case setFirstLaunch(Date)
    case runningShaked
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {

      case .appLaunched:
        return .merge(
          .run { send in
            await send(.setRunning(self.systemExtension.filterRunning()))
          },
          .run { _ in
            let blockRules = try await self.api.fetchBlockRules()
            self.storage.saveBlockRules(blockRules)
          },
          .run { send in
            if let firstLaunch = self.storage.loadFirstLaunchDate() {
              await send(.setFirstLaunch(firstLaunch))
            } else {
              let now = self.now
              self.storage.saveFirstLaunchDate(now)
              await send(.setFirstLaunch(now))
              await self.api.logEvent(
                "dcd721aa",
                "first launch, region: `\(self.locale.region?.identifier ?? "(nil)")`"
              )
            }
          }
        )

      case .setRunning(true):
        state.appState = .running(showVendorId: false)
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
          switch await self.systemExtension.requestAuthorization() {
          case .success:
            await send(.authorizationSucceeded)
            await self.api.logEvent("d317c73c", "authorization succeeded")
          case .failure(let reason):
            await send(.authorizationFailed(reason))
            await self.systemExtension.cleanupForRetry()
            await self.api.logEvent("d9dfd021", "authorization failed: \(reason)")
          }
        }

      case .authorizationSucceeded:
        state.appState = .authorized
        return .none

      case .authorizationFailed(let reason):
        state.appState = .authorizationFailed(reason)
        return .none

      case .authorizationFailedReviewRequirementsTapped:
        state.appState = .prereqs
        return .none

      case .authorizationFailedTryAgainTapped:
        state.appState = .welcome
        return .none

      case .installFilterTapped:
        return .run { send in
          switch await self.systemExtension.installFilter() {
          case .success:
            await send(.installSucceeded)
            await self.api.logEvent("101c91ea", "filter install success")
          case .failure(let error):
            await send(.installFailed(error))
            await self.systemExtension.cleanupForRetry()
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
        state.appState = .running(showVendorId: false)
        return .none

      case .runningShaked:
        guard case .running = state.appState else { return .none }
        state.appState = .running(showVendorId: true)
        return .run { _ in
          let blockRules = try await self.api.fetchBlockRules()
          self.storage.saveBlockRules(blockRules)
          try await self.filter.notifyRulesChanged()
        }
      }
    }
  }

  public init() {}
}
