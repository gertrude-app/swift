import Combine
import Core
import Dependencies
import Shared

public struct FilterXPCClient: Sendable {

  public var establishConnection: @Sendable () async -> Result<Void, XPCErr>
  public var isConnectionHealthy: @Sendable () async -> Result<Void, XPCErr>
  public var sendUserRules: @Sendable (AppIdManifest, [FilterKey]) async -> Result<Void, XPCErr>
  public var setBlockStreaming: @Sendable (Bool) async -> Result<Void, XPCErr>
  public var events: @Sendable () -> AnyPublisher<XPCEvent.App, Never>

  public init(
    establishConnection: @escaping @Sendable () async -> Result<Void, XPCErr>,
    isConnectionHealthy: @escaping @Sendable () async -> Result<Void, XPCErr>,
    sendUserRules: @escaping @Sendable (AppIdManifest, [FilterKey]) async -> Result<Void, XPCErr>,
    setBlockStreaming: @escaping @Sendable (Bool) async -> Result<Void, XPCErr>,
    events: @escaping @Sendable () -> AnyPublisher<XPCEvent.App, Never>
  ) {
    self.establishConnection = establishConnection
    self.isConnectionHealthy = isConnectionHealthy
    self.sendUserRules = sendUserRules
    self.setBlockStreaming = setBlockStreaming
    self.events = events
  }
}

extension FilterXPCClient: TestDependencyKey {
  public static var testValue: Self {
    .init(
      establishConnection: { .success(()) },
      isConnectionHealthy: { .success(()) },
      sendUserRules: { _, _ in .success(()) },
      setBlockStreaming: { _ in .success(()) },
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
