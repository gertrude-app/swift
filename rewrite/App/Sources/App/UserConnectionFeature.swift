import ComposableArchitecture
import Models
import PairQL

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
      return .run { _ in
        await setUserToken(user.token)
      }

    case .connect(.failure(let error)):
      let codeNotFound = "Code not found, or expired. Try reentering, or create a new code."
      state = .connectFailed(error.userMessage([.connectionCodeNotFound: codeNotFound]))
      return .none
    }
  }
}

extension UserConnectionFeature.Reducer {
  typealias State = UserConnectionFeature.State
  typealias Action = UserConnectionFeature.Action
}
