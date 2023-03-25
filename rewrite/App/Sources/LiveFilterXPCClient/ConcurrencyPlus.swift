import Foundation
import Models

// @see https://github.com/ChimeHQ/ConcurrencyPlus
// @see https://www.chimehq.com/blog/extensionkit-xpc
// error type extended

public enum ConnectionContinuationError: Error {
  case serviceTypeMismatch
  case missingBothValueAndError
  case remoteProxyError(Error)
  case replyError(Error)
}

public extension NSXPCConnection {
  // Create a continuation that is automatically cancelled on connection failure
  func withContinuation<Service, T>(
    function: String = #function,
    _ body: (Service, CheckedContinuation<T, Error>) -> Void
  ) async throws -> T {
    try await withCheckedThrowingContinuation(function: function) { continuation in
      let proxy = self.remoteObjectProxyWithErrorHandler { error in
        continuation.resume(throwing: ConnectionContinuationError.remoteProxyError(error))
      }

      guard let service = proxy as? Service else {
        continuation.resume(throwing: ConnectionContinuationError.serviceTypeMismatch)
        return
      }

      body(service, continuation)
    }
  }
}

public extension CheckedContinuation where T == Void {
  func resume(with error: E?) {
    if let error = error {
      resume(throwing: error)
    } else {
      resume()
    }
  }
}

public extension CheckedContinuation where E == Error {
  func resume(with value: T?, error: Error?) {
    switch (value, error) {
    case (let value?, nil):
      resume(returning: value)
    case (_, let error?):
      resume(throwing: ConnectionContinuationError.replyError(error))
    case (nil, nil):
      resume(throwing: ConnectionContinuationError.missingBothValueAndError)
    }
  }

  var resumingHandler: (T?, Error?) -> Void {
    { resume(with: $0, error: $1) }
  }
}

public extension CheckedContinuation where T == Void, E == Error {
  var resumingHandler: (Error?) -> Void {
    { resume(with: $0) }
  }
}

public extension CheckedContinuation where T: Decodable, E == Error {
  func resume(with data: Data?, error: Error?) {
    switch (data, error) {
    case (_, let error?):
      resume(throwing: ConnectionContinuationError.replyError(error))
    case (nil, nil):
      resume(throwing: ConnectionContinuationError.missingBothValueAndError)
    case (let encodedValue?, nil):
      let result = Swift.Result(catching: { try JSONDecoder().decode(T.self, from: encodedValue) })
      resume(with: result)
    }
  }

  var resumingHandler: (Data?, Error?) -> Void {
    { resume(with: $0, error: $1) }
  }
}
