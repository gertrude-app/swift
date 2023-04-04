import Core
import Dependencies

struct XPCClient: Sendable {
  var startListener: @Sendable () async -> Void
  var sendUuid: @Sendable () async throws -> Void
}

extension XPCClient: DependencyKey {
  static var liveValue: Self {
    let manager = ThreadSafeXPCManager()
    return .init(
      startListener: { await manager.startListener() },
      sendUuid: { try await manager.sendUuid() }
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

actor ThreadSafeXPCManager {
  private var manager = XPCManager()

  func startListener() {
    manager.startListener()
  }

  func sendUuid() async throws {
    try await manager.sendUuid()
  }
}
