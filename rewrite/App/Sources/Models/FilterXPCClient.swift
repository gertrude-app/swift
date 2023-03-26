import Combine
import Core
import Dependencies
import Foundation

public struct FilterXPCClient: Sendable {
  public var establishConnection: @Sendable () async -> Result<Void, XPCErr>
  public var isConnectionHealthy: @Sendable () async -> Result<Void, XPCErr>
  public var events: @Sendable () -> AnyPublisher<XPCEvent, Never>

  public init(
    establishConnection: @escaping @Sendable () async -> Result<Void, XPCErr>,
    isConnectionHealthy: @escaping @Sendable () async -> Result<Void, XPCErr>,
    events: @escaping @Sendable () -> AnyPublisher<XPCEvent, Never>
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
