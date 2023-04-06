import ComposableArchitecture

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
