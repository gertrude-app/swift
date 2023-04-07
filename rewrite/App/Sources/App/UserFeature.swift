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
    @Dependency(\.filterXpc) var filterXpc

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {

      case .refreshRules(.success(let output)):
        state.screenshotSize = output.screenshotsResolution
        state.screenshotFrequency = output.screenshotsFrequency
        state.keyloggingEnabled = output.keyloggingEnabled
        state.screenshotsEnabled = output.screenshotsEnabled
        return .fireAndForget {
          // TODO: handle errors...
          _ = await filterXpc.sendUserRules(
            output.appManifest,
            output.keys.map { .init(id: $0.id, key: $0.key) }
          )
        }

      case .heartbeat(let interval) where interval == .everyTwentyMinutes:
        return .task {
          await .refreshRules(TaskResult { try await api.refreshUserRules() })
        }

      case .heartbeat:
        return .none

      case .refreshRules(.failure):
        return .none
      }
    }
  }
}
