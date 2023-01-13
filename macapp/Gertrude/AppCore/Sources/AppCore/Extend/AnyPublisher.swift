import Combine

extension AnyPublisher where Output == Bool, Failure == Never {
  static var `true` = Just(true).eraseToAnyPublisher()
  static var `false` = Just(true).eraseToAnyPublisher()
}
