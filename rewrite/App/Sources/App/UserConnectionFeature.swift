import ComposableArchitecture
import Models

enum UserConnectionFeature: Feature {
  enum State: Equatable {
    case notConnected
    case enteringConnectionCode
    case connecting
    case connectFailed(String)
    case established(welcomeDismissed: Bool)
  }

  enum Action: Equatable, Sendable {
    case connect(TaskResult<User>)
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.api.setUserToken) var setUserToken
  }
}

extension UserConnectionFeature.Reducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .connect(.success(let user)):
      state = .established(welcomeDismissed: false)
      return .fireAndForget {
        await setUserToken(user.token)
      }
    case .connect(.failure(let error)):
      state = .connectFailed(error.localizedDescription)
      return .none
    }
  }
}

extension UserConnectionFeature.Reducer {
  typealias State = UserConnectionFeature.State
  typealias Action = UserConnectionFeature.Action
}
