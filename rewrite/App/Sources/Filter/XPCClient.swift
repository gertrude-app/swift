import Core
import Dependencies

struct XPCClient: Sendable {
  var startListener: @Sendable () async -> Void
  var sendUuid: @Sendable () async throws -> Void
}

extension XPCClient: DependencyKey {
  static var liveValue: Self {
    let manager = ThreadSafe(XPCManager())
    return .init(
      startListener: { manager.value.startListener() },
      sendUuid: { try await manager.value.sendUuid() }
    )
  }
}

extension XPCClient: TestDependencyKey {
  static let testValue = Self(
    startListener: {},
    sendUuid: {}
  )
}

extension DependencyValues {
  var xpc: XPCClient {
    get { self[XPCClient.self] }
    set { self[XPCClient.self] = newValue }
  }
}
