import Combine
import Foundation
import MacAppRoute
import Gertie
import SharedCore
import TaggedTime

public struct ApiClient {
  public enum Error: Swift.Error {
    case precondition(String, String)
    case pql(String, PqlError)
    case generic(String, Swift.Error)
  }

  struct RefreshRulesData: Equatable {
    let keyLoggingEnabled: Bool
    let screenshotsEnabled: Bool
    let screenshotsFrequency: Int
    let screenshotsResolution: Int
    let keys: [FilterKey]
    let idManifest: AppIdManifest
  }

  typealias UserData = (userId: UUID, userToken: UUID, userName: String, deviceId: UUID)

  var connectToUser: (Int) -> AnyPublisher<UserData, Error>
  var createSuspendFilterRequest: (Seconds<Int>, String?) -> AnyPublisher<Void, Error>
  var createUnlockRequests: (Set<UUID>, String?) -> AnyPublisher<Void, Error>
  var getAccountStatus: () -> AnyPublisher<AdminAccountStatus, Error>
  var refreshRules: () -> AnyPublisher<RefreshRulesData, Error>
  var uploadFilterDecisions: ([FilterDecision]) -> Void
  var uploadKeystrokes: () -> Void
  var uploadScreenshot: (Data, Int, Int, ((String?) -> Void)?) -> Void
}

// extensions

extension ApiClient.Error {
  var logged: Self {
    switch self {
    case .pql(let operationName, let pqlError):
      log(.api(.pqlError(operationName, pqlError)))
    case .generic(let operationName, let error):
      log(.api(.error("error from operation: \(operationName)", error)))
    case .precondition(let operationName, let message):
      log(.api(.error(
        "Precondition for operation \(operationName) failed with message: \(message)",
        nil
      )))
    }
    return self
  }

  var tag: PqlError.AppTag? {
    switch self {
    case .pql(_, let pqlError):
      return pqlError.appTag
    default:
      return nil
    }
  }
}

extension ApiClient.Error: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.precondition(let lhsOp, let lhsMsg), .precondition(let rhsOp, let rhsMsg)):
      return lhsOp == rhsOp && lhsMsg == rhsMsg
    case (.pql(let lhsOp, let lhsErr), .pql(let rhsOp, let rhsErr)):
      return lhsOp == rhsOp && lhsErr == rhsErr
    case (.generic(let lhsOp, let lhsErr), .generic(let rhsOp, let rhsErr)):
      return lhsOp == rhsOp && ~lhsErr == ~rhsErr
    default:
      return false
    }
  }
}

extension ApiClient.Error: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .pql(let operation, let pql):
      return "PairQL error from operation \(operation): \(pql.debugMessage)"
    case .generic(let operation, let error):
      if let error = error as? LocalizedError {
        return "Error from operation \(operation): \(error.errorDescription ?? "unknown error")"
      } else {
        return "Error from operation \(operation): \(error.localizedDescription)"
      }
    case .precondition(let operation, let message):
      return "Precondition for operation \(operation) failed with message: \(message)"
    }
  }
}

extension ApiClient {
  static let noop = ApiClient(
    connectToUser: { _ in Empty().eraseToAnyPublisher() },
    createSuspendFilterRequest: { _, _ in Empty().eraseToAnyPublisher() },
    createUnlockRequests: { _, _ in Empty().eraseToAnyPublisher() },
    getAccountStatus: { Empty().eraseToAnyPublisher() },
    refreshRules: { Empty().eraseToAnyPublisher() },
    uploadFilterDecisions: { _ in },
    uploadKeystrokes: {},
    uploadScreenshot: { _, _, _, _ in }
  )
}
