import ComposableArchitecture
import Foundation

typealias FeatureReducer = Reducer

protocol Feature {
  associatedtype State: Equatable
  associatedtype Action: Equatable, Sendable
  associatedtype Reducer: FeatureReducer
}

protocol RootReducing: Reducer {
  associatedtype State = AppReducer.State
  associatedtype Action = AppReducer.Action
}

protocol AdminAuthenticating: RootReducing {
  var security: SecurityClient { get }
}

extension AdminAuthenticating where Action == AppReducer.Action {
  func adminAuthenticated(_ action: Action) -> Effect<Action> {
    .run { [didAuthenticateAsAdmin = security.didAuthenticateAsAdmin] send in
      if await didAuthenticateAsAdmin() {
        await send(.adminAuthenticated(action))
      }
    }
  }
}

enum Heartbeat {
  enum Interval: Equatable, Sendable {
    case everyMinute
    case everyFiveMinutes
    case everyTwentyMinutes
    case everySixHours
  }

  enum CancelId {}
}

enum NotificationsSetting: String, Equatable, Codable {
  case none
  case banner
  case alert
}

extension AnySchedulerOf<DispatchQueue> {
  func schedule(after time: DispatchQueue.SchedulerTimeType.Stride, action: @escaping () -> Void) {
    schedule(after: now.advanced(by: time), action)
  }
}
