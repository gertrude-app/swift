import Foundation

public enum XPCErr: Error, Sendable {
  public enum AppErr: Error, Sendable {
    case unexpectedIncorrectAck
    case filterNotInstalled
  }

  case noConnection
  case onAppSide(AppErr)
  case remoteProxyCastFailed
  case remoteProxyError(Error)
  case replyError(Error)
  case unknownError(Error)
  case unexpectedMissingValueAndError
  case timeout
  case encode(fn: StaticString, type: Encodable.Type, error: Error)
  case decode(fn: StaticString, type: Decodable.Type, error: Error)
}

public extension XPCErr {
  init(_ error: Error) {
    switch error {
    case let error as XPCErr:
      self = error
    case let connectionError as XPCContinuationErr:
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

public enum XPCEvent: Sendable, Equatable {
  public enum MessageFromExtension: Sendable, Equatable {
    case uuid(UUID)
  }

  case receivedExtensionMessage(MessageFromExtension)
  case decodingExtensionDataFailed(fn: String, type: String, error: String)
}

public extension Result where Failure == XPCErr {
  init(catching body: @escaping () async throws -> Success) async {
    do {
      self = .success(try await body())
    } catch {
      self = .failure(.init(error))
    }
  }
}

public extension Result {
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
