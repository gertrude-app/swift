import ComposableArchitecture
import MacAppRoute
import Models

struct UserReducer: Reducer {
  typealias State = User

  enum Action: Equatable, Sendable {
    case refreshRules(TaskResult<RefreshRules.Output>)
  }

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .refreshRules(.success(let output)):
      state.screenshotSize = output.screenshotsResolution
      state.screenshotFrequency = output.screenshotsFrequency
      state.keyloggingEnabled = output.keyloggingEnabled
      state.screenshotsEnabled = output.screenshotsEnabled
      return .none
    case .refreshRules(.failure):
      return .none
    }
  }
}
