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
  public var requestUserTypes: @Sendable () async -> Result<FilterUserTypes, XPCErr>
  public var sendDeleteAllStoredState: @Sendable () async -> Result<Void, XPCErr>
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
    requestUserTypes: @escaping @Sendable () async -> Result<FilterUserTypes, XPCErr>,
    sendDeleteAllStoredState: @escaping @Sendable () async -> Result<Void, XPCErr>,
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
    self.requestUserTypes = requestUserTypes
    self.sendDeleteAllStoredState = sendDeleteAllStoredState
    self.sendUserRules = sendUserRules
    self.setBlockStreaming = setBlockStreaming
    self.setUserExemption = setUserExemption
    self.suspendFilter = suspendFilter
    self.events = events
  }

  public func connected(attemptRepair: Bool = false) async -> Bool {
    if await self.checkConnectionHealth().isSuccess {
      return true
    } else if attemptRepair {
      return await self.establishConnection().isSuccess
    } else {
      return false
    }
  }

  public func notConnected() async -> Bool {
    await self.connected() == false
  }
}

extension FilterXPCClient: TestDependencyKey {
  public static var testValue: Self {
    .init(
      establishConnection: unimplemented(
        "FilterXPCClient.establishConnection",
        placeholder: .success(())
      ),
      checkConnectionHealth: unimplemented(
        "FilterXPCClient.checkConnectionHealth",
        placeholder: .success(())
      ),
      disconnectUser: unimplemented(
        "FilterXPCClient.disconnectUser",
        placeholder: .success(())
      ),
      endFilterSuspension: unimplemented(
        "FilterXPCClient.endFilterSuspension",
        placeholder: .success(())
      ),
      requestAck: unimplemented(
        "FilterXPCClient.requestAck",
        placeholder: .success(.init(randomInt: 0, version: "", userId: 0, numUserKeys: 0))
      ),
      requestUserTypes: unimplemented(
        "FilterXPCClient.requestUserTypes",
        placeholder: .success(.init(exempt: [], protected: []))
      ),
      sendDeleteAllStoredState: unimplemented(
        "FilterXPCClient.sendDeleteAllStoredState",
        placeholder: .success(())
      ),
      sendUserRules: unimplemented(
        "FilterXPCClient.sendUserRules",
        placeholder: .success(())
      ),
      setBlockStreaming: unimplemented(
        "FilterXPCClient.setBlockStreaming",
        placeholder: .success(())
      ),
      setUserExemption: unimplemented(
        "FilterXPCClient.setUserExemption",
        placeholder: .success(())
      ),
      suspendFilter: unimplemented(
        "FilterXPCClient.suspendFilter",
        placeholder: .success(())
      ),
      events: unimplemented(
        "FilterXPCClient.events",
        placeholder: AnyPublisher(Empty())
      )
    )
  }

  public static var mock: Self {
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
      requestUserTypes: { .success(.init(exempt: [], protected: [])) },
      sendDeleteAllStoredState: { .success(()) },
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
