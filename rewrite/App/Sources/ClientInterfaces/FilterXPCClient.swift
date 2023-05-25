import Combine
import Core
import Dependencies
import Foundation
import Gertie
import TaggedTime

public struct FilterXPCClient: Sendable {
  public var establishConnection: @Sendable () async -> Result<Void, XPCErr>
  public var checkConnectionHealth: @Sendable () async -> Result<Void, XPCErr>
  public var disconnectUser: @Sendable () async -> Result<Void, XPCErr>
  public var endFilterSuspension: @Sendable () async -> Result<Void, XPCErr>
  public var requestAck: @Sendable () async -> Result<XPC.FilterAck, XPCErr>
  public var requestExemptUserIds: @Sendable () async -> Result<[uid_t], XPCErr>
  public var sendPrepareForUninstall: @Sendable () async -> Result<Void, XPCErr>
  public var sendUserRules: @Sendable (AppIdManifest, [FilterKey]) async -> Result<Void, XPCErr>
  public var setBlockStreaming: @Sendable (Bool) async -> Result<Void, XPCErr>
  public var setUserExemption: @Sendable (uid_t, Bool) async -> Result<Void, XPCErr>
  public var suspendFilter: @Sendable (Seconds<Int>) async -> Result<Void, XPCErr>
  public var events: @Sendable () -> AnyPublisher<XPCEvent.App, Never>

  public init(
    establishConnection: @escaping @Sendable () async -> Result<Void, XPCErr>,
    checkConnectionHealth: @escaping @Sendable () async -> Result<Void, XPCErr>,
    disconnectUser: @escaping @Sendable () async -> Result<Void, XPCErr>,
    endFilterSuspension: @escaping @Sendable () async -> Result<Void, XPCErr>,
    requestAck: @escaping @Sendable () async -> Result<XPC.FilterAck, XPCErr>,
    requestExemptUserIds: @escaping @Sendable () async -> Result<[uid_t], XPCErr>,
    sendPrepareForUninstall: @escaping @Sendable () async -> Result<Void, XPCErr>,
    sendUserRules: @escaping @Sendable (AppIdManifest, [FilterKey]) async -> Result<Void, XPCErr>,
    setBlockStreaming: @escaping @Sendable (Bool) async -> Result<Void, XPCErr>,
    setUserExemption: @escaping @Sendable (uid_t, Bool) async -> Result<Void, XPCErr>,
    suspendFilter: @escaping @Sendable (Seconds<Int>) async -> Result<Void, XPCErr>,
    events: @escaping @Sendable () -> AnyPublisher<XPCEvent.App, Never>
  ) {
    self.establishConnection = establishConnection
    self.checkConnectionHealth = checkConnectionHealth
    self.disconnectUser = disconnectUser
    self.endFilterSuspension = endFilterSuspension
    self.requestAck = requestAck
    self.requestExemptUserIds = requestExemptUserIds
    self.sendPrepareForUninstall = sendPrepareForUninstall
    self.sendUserRules = sendUserRules
    self.setBlockStreaming = setBlockStreaming
    self.setUserExemption = setUserExemption
    self.suspendFilter = suspendFilter
    self.events = events
  }

  public func connected() async -> Bool {
    await checkConnectionHealth().isSuccess
  }

  public func notConnected() async -> Bool {
    await connected() == false
  }
}

extension FilterXPCClient: TestDependencyKey {
  public static var testValue: Self {
    .init(
      establishConnection: { .success(()) },
      checkConnectionHealth: { .success(()) },
      disconnectUser: { .success(()) },
      endFilterSuspension: { .success(()) },
      requestAck: { .success(.init(
        randomInt: 0,
        version: "",
        userId: 0,
        numUserKeys: 0
      )) },
      requestExemptUserIds: { .success([]) },
      sendPrepareForUninstall: { .success(()) },
      sendUserRules: { _, _ in .success(()) },
      setBlockStreaming: { _ in .success(()) },
      setUserExemption: { _, _ in .success(()) },
      suspendFilter: { _ in .success(()) },
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
