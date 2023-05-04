import ComposableArchitecture
import Shared

struct AppUpdatesFeature: Feature {
  struct State: Equatable {
    var latestVersion: String?
    var releaseChannel: ReleaseChannel = .stable // todo, should persist
  }

  enum Action: Equatable, Sendable {
    case latestVersionResponse(TaskResult<String>)
  }

  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {

      case .latestVersionResponse(.success(let version)):
        state.latestVersion = version
        return .none

      case .latestVersionResponse(.failure):
        return .none
      }
    }
  }

  struct RootReducer {
    @Dependency(\.updater) var updater
  }
}

extension AppUpdatesFeature.RootReducer: RootReducing {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .adminWindow(.delegate(.triggerAppUpdate)):
      // need to hold on to current app version in persisted state, so we can compare on launch
      // on restoration of stored app version, detect if we just updated, restart filter
      // do we need the concept of a filter restart failsafe?
      // - maybe when we boot into this condition, show a new window, w/ button to restart filter
      // - and feedback, so that the admin can see if the filter failed to restart
      // - or, better yet, restart the filter, and if it fails, immediately pop up the health-check
      // figure out how to assemble update string
      return .none

    default:
      return .none
    }
  }
}
