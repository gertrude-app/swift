import Foundation
import Gertie

public struct UserFilterData: Sendable, Codable {
  public var keychains: [RuleKeychain]
  public var downtime: Downtime?

  public init(keychains: [RuleKeychain], downtime: Downtime? = nil) {
    self.keychains = keychains
    self.downtime = downtime
  }
}

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
  public enum App: Sendable, Equatable {
    public enum MessageFromExtension: Sendable, Equatable {
      case blockedRequest(BlockedRequest)
      case userFilterSuspensionEnded(uid_t)
      case logs(FilterLogs)
    }

    case receivedExtensionMessage(MessageFromExtension)
    case decodingExtensionMessageDataFailed(fn: String, type: String, error: String)
  }
}

public extension XPC {
  enum URLMessage: Sendable, Equatable {
    case alive(uid_t)
    case restartListener(uid_t)

    public var string: String {
      switch self {
      case .alive(let userId):
        return "x-alive--\(userId)"
      case .restartListener(let userId):
        return "x-restart-listener--\(userId)"
      }
    }

    public var hostname: String {
      "\(self.string).xpc.gertrude.app"
    }

    public var url: URL {
      URL(string: "https://\(self.hostname)")!
    }

    public init?(string: String) {
      guard string.starts(with: "x") else {
        return nil
      }
      if string.starts(with: "x-alive--") {
        if let uid = uid_t(login: string.dropFirst(9)) {
          self = .alive(uid)
        }
      } else if string.starts(with: "x-restart-listener--") {
        if let uid = uid_t(login: string.dropFirst(20)) {
          self = .restartListener(uid)
        }
      }
      return nil
    }
  }
}

private extension uid_t {
  init?(login: Substring) {
    if let num = UInt32(login), num > 500 {
      self = num
    } else {
      return nil
    }
  }
}

public extension XPC {
  struct FilterAck: Sendable, Equatable, Codable {
    public var randomInt: Int
    public var version: String
    public var userId: uid_t
    public var numUserKeys: Int

    public init(randomInt: Int, version: String, userId: uid_t, numUserKeys: Int) {
      self.randomInt = randomInt
      self.version = version
      self.userId = userId
      self.numUserKeys = numUserKeys
    }
  }
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
    !self.isSuccess
  }
}
