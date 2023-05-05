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

enum Heartbeat {
  enum Interval: Equatable, Sendable {
    case everyMinute
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

enum MacOsUserType: String, Equatable, Codable, Sendable {
  case standard
  case admin
}

extension AnySchedulerOf<DispatchQueue> {
  func schedule(after time: DispatchQueue.SchedulerTimeType.Stride, action: @escaping () -> Void) {
    schedule(after: now.advanced(by: time), action)
  }
}
