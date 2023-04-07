import Foundation

public enum XPCErr: Error, Sendable, Codable {
  public enum AppErr: Error, Sendable, Codable {
    case unexpectedIncorrectAck
    case filterNotInstalled
  }

  case noConnection
  case onAppSide(AppErr)
  case remoteProxyCastFailed
  case remoteProxyError(String)
  case replyError(String)
  case unknownError(String)
  case unexpectedMissingValueAndError
  case timeout
  case encode(fn: String, type: String, error: String)
  case decode(fn: String, type: String, error: String)
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
        self = .remoteProxyError(String(describing: error))
      case .replyError(let error):
        self = .replyError(String(describing: error))
      case .serviceTypeMismatch:
        self = .remoteProxyCastFailed
      }
    default:
      self = .unknownError(String(describing: error))
    }
  }

  init(data: Data) {
    if let error = try? JSONDecoder().decode(XPCErr.self, from: data) {
      self = error
    } else {
      self = .unknownError(String(decoding: data, as: UTF8.self))
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
