import ComposableArchitecture
import Gertie
import MacAppRoute

struct UserFeature: Feature {
  struct State: Equatable, Sendable {
    var data: UserData?
    var numTimesUserTokenNotFound = 0
  }

  enum Action: Sendable, Equatable {
    case updated(previous: UserData?)
  }

  struct RootReducer {
    typealias Action = AppReducer.Action
    typealias State = AppReducer.State
    @Dependency(\.api) var api
  }
}

extension UserFeature.RootReducer: RootReducing {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    // these websocket messages mean we need to check back in for updated data
    case .websocket(.receivedMessage(.userUpdated)),
         .websocket(.receivedMessage(.unlockRequestUpdated(.accepted, _, _))):
      return .exec { [filterVersion = state.filter.version] send in
        await send(.checkIn(
          result: TaskResult { try await api.appCheckIn(filterVersion) },
          reason: .receivedWebsocketMessage
        ))
      }

    case .heartbeat(.everySixHours):
      let timesTokenNotFound = state.user.numTimesUserTokenNotFound
      return timesTokenNotFound >= 8
        ? .exec { send in await send(.history(.userConnection(.disconnectMissingUser))) }
        : .none

    default:
      return .none
    }
  }
}

extension UserFeature {
  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      .none
    }
  }
}
