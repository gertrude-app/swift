import Combine
import Dependencies

public struct FilterXPCClient: Sendable {
  public var establishConnection: @Sendable () async -> Result<Void>
  public var isConnectionHealthy: @Sendable () async -> Result<Void>
  public var events: @Sendable () async -> AnyPublisher<Event, Never>

  public init(
    establishConnection: @escaping @Sendable () async -> Result<Void>,
    isConnectionHealthy: @escaping @Sendable () async -> Result<Void>,
    events: @escaping @Sendable () async -> AnyPublisher<Event, Never>
  ) {
    self.establishConnection = establishConnection
    self.isConnectionHealthy = isConnectionHealthy
    self.events = events
  }
}

extension FilterXPCClient: TestDependencyKey {
  public static var testValue: Self {
    .init(
      establishConnection: { .success(()) },
      isConnectionHealthy: { .success(()) },
      events: { Empty().eraseToAnyPublisher() }
    )
  }
}

public extension DependencyValues {
  var filterXpc: FilterXPCClient {
    get { self[FilterXPCClient.self] }
    set { self[FilterXPCClient.self] = newValue }
  }
}

public extension FilterXPCClient {
  typealias Result<T> = Swift.Result<T, Error>

  enum Event {
    public enum MessageFromExtension: Sendable {
      case todo
    }

    case receivedExtensionMessage(MessageFromExtension)
    // TODO: errors, invalidation handlers called, lost connection, etc...
  }

  enum Error: UnwrappableError, Sendable {
    case unwrapFailed
    case remoteProxyCastFailed
    case remoteProxyError(Swift.Error)
    case replyError(Swift.Error)
    case unknownError(Swift.Error)
    case unexpectedMissingValueAndError
    case unexpectedIncorrectAck
    case timeout
    case filterNotInstalled
    case encode(fn: StaticString, type: Encodable.Type, error: Swift.Error)
    case decode(fn: StaticString, type: Decodable.Type, error: Swift.Error)
  }
}

public protocol UnwrappableError: Swift.Error {
  static var unwrapFailed: Self { get }
}

public extension Swift.Result where Failure: UnwrappableError {
  func unwrapFailure() -> Failure {
    guard case .failure(let err) = self else {
      return Failure.unwrapFailed
    }
    return err
  }
}
