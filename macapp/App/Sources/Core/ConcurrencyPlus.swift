import Foundation

// @see https://github.com/ChimeHQ/ConcurrencyPlus
// @see https://www.chimehq.com/blog/extensionkit-xpc
// error type extended

public enum XPCContinuationErr: Error {
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
        continuation.resume(throwing: XPCContinuationErr.remoteProxyError(error))
      }

      guard let service = proxy as? Service else {
        continuation.resume(throwing: XPCContinuationErr.serviceTypeMismatch)
        return
      }

      body(service, continuation)
    }
  }
}

public extension CheckedContinuation where T == Void {
  func resume(with error: E?) {
    if let error {
      self.resume(throwing: error)
    } else {
      self.resume()
    }
  }
}

public extension CheckedContinuation where E == Error {
  func resume(with value: T?, error: Error?) {
    switch (value, error) {
    case (let value?, nil):
      self.resume(returning: value)
    case (_, let error?):
      self.resume(throwing: XPCContinuationErr.replyError(error))
    case (nil, nil):
      self.resume(throwing: XPCContinuationErr.missingBothValueAndError)
    }
  }

  var resumingHandler: (T?, Error?) -> Void {
    { resume(with: $0, error: $1) }
  }

  var dataHandler: (T?, Data?) -> Void {
    { resume(with: $0, error: $1.map(XPCErr.init(data:))) }
  }
}

public extension CheckedContinuation where T == Void, E == Error {
  var resumingHandler: (Error?) -> Void {
    { resume(with: $0) }
  }

  var dataHandler: (Data?) -> Void {
    { resume(with: $0.map(XPCErr.init(data:))) }
  }
}

public extension CheckedContinuation where T: Decodable, E == Error {
  func resume(with data: Data?, error: Error?) {
    switch (data, error) {
    case (_, let error?):
      self.resume(throwing: XPCContinuationErr.replyError(error))
    case (nil, nil):
      self.resume(throwing: XPCContinuationErr.missingBothValueAndError)
    case (let encodedValue?, nil):
      let result = Swift.Result(catching: { try JSONDecoder().decode(T.self, from: encodedValue) })
      self.resume(with: result)
    }
  }

  var resumingHandler: (Data?, Error?) -> Void {
    { resume(with: $0, error: $1) }
  }

  var dataHandler: (Data?, Data?) -> Void {
    { resume(with: $0, error: $1.map(XPCErr.init(data:))) }
  }
}
