import Combine

extension AnyPublisher where Output == Bool, Failure == Never {
  static var `true` = Just(true).eraseToAnyPublisher()
  static var `false` = Just(true).eraseToAnyPublisher()
}

extension AnyPublisher {
  enum AsyncError: Error {
    case finishedWithoutValue
  }

  func async() async throws -> Output {
    try await withCheckedThrowingContinuation { continuation in
      var cancellable: AnyCancellable?
      var finishedWithoutValue = true
      cancellable = first()
        .sink { result in
          switch result {
          case .finished:
            if finishedWithoutValue {
              continuation.resume(throwing: AsyncError.finishedWithoutValue)
            }
          case .failure(let error):
            continuation.resume(throwing: error)
          }
          cancellable?.cancel()
        } receiveValue: { value in
          finishedWithoutValue = false
          continuation.resume(with: .success(value))
        }
    }
  }
}
