import ComposableArchitecture
import MacAppRoute
import Models

struct UserFeature: Feature {
  typealias State = User

  enum Action: Equatable, Sendable {
    case refreshRules(TaskResult<RefreshRules.Output>)
    case heartbeat(Heartbeat.Interval)
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.api) var api
    @Dependency(\.app) var appClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {

      case .refreshRules(.success(let output)):
        state.screenshotSize = output.screenshotsResolution
        state.screenshotFrequency = output.screenshotsFrequency
        state.keyloggingEnabled = output.keyloggingEnabled
        state.screenshotsEnabled = output.screenshotsEnabled
        return .none

      case .heartbeat(let interval) where interval == .everyTwentyMinutes:
        return .task {
          await .refreshRules(TaskResult {
            let appVersion = appClient.installedVersion() ?? "unknown"
            return try await api.refreshRules(.init(appVersion: appVersion))
          })
        }

      case .heartbeat:
        return .none

      case .refreshRules(.failure):
        return .none
      }
    }
  }
}
