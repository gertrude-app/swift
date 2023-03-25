import Models

extension FilterXPCClient.Error {
  init(_ error: Error) {
    switch error {
    case let error as FilterXPCClient.Error:
      self = error
    case let connectionError as ConnectionContinuationError:
      switch connectionError {
      case .missingBothValueAndError:
        self = .unexpectedMissingValueAndError
      case .remoteProxyError(let error):
        self = .remoteProxyError(error)
      case .replyError(let error):
        self = .replyError(error)
      case .serviceTypeMismatch:
        self = .remoteProxyCastFailed
      }
    default:
      self = .unknownError(error)
    }
  }
}

extension Result where Failure == FilterXPCClient.Error {
  init(catching body: @escaping () async throws -> Success) async {
    do {
      self = .success(try await body())
    } catch {
      self = .failure(.init(error))
    }
  }
}

extension Result {
  var isSuccess: Bool {
    switch self {
    case .success:
      return true
    case .failure:
      return false
    }
  }

  var isFailure: Bool {
    !isSuccess
  }
}
