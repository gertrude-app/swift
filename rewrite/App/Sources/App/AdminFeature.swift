import ComposableArchitecture
import Shared

struct AdminFeature: Feature {
  struct State: Equatable {
    var accountStatus: AdminAccountStatus = .active
  }

  enum Action: Equatable, Sendable {
    case accountStatusResponse(TaskResult<AdminAccountStatus>)
  }

  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .accountStatusResponse(.success(let status)):
        state.accountStatus = status
        return .none
      case .accountStatusResponse(.failure):
        return .none
      }
    }
  }

  struct RootReducer {}
}

extension AdminFeature.RootReducer: RootReducing {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    .none
  }
}
