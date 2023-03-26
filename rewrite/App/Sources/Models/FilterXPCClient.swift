import Combine
import Core
import Dependencies

public struct FilterXPCClient: Sendable {
  public var establishConnection: @Sendable () async -> Result<Void, XPCErr>
  public var isConnectionHealthy: @Sendable () async -> Result<Void, XPCErr>
  public var events: @Sendable () async -> AnyPublisher<Event, Never>

  public init(
    establishConnection: @escaping @Sendable () async -> Result<Void, XPCErr>,
    isConnectionHealthy: @escaping @Sendable () async -> Result<Void, XPCErr>,
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

  enum Event {
    public enum MessageFromExtension: Sendable {
      case todo
    }

    case receivedExtensionMessage(MessageFromExtension)
    // TODO: errors, invalidation handlers called, lost connection, etc...
  }
}
