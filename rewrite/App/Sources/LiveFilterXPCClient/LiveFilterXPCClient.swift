import Core
import Dependencies
import Models
import Shared

extension FilterXPCClient: DependencyKey {
  public static var liveValue: Self {
    let xpc = ThreadSafeFilterXPC()
    return .init(
      establishConnection: { await .init {
        try await xpc.establishConnection()
      }},
      checkConnectionHealth: { await .init {
        try await xpc.checkConnectionHealth()
      }},
      requestAck: { await .init {
        try await xpc.requestAck()
      }},
      sendUserRules: { manifest, keys in await .init {
        try await xpc.sendUserRules(manifest: manifest, keys: keys)
      }},
      setBlockStreaming: { enabled in await .init {
        try await xpc.setBlockStreaming(enabled: enabled)
      }},
      events: {
        xpcEventSubject.withValue { subject in
          Move(subject.eraseToAnyPublisher())
        }.consume()
      }
    )
  }
}

actor ThreadSafeFilterXPC {
  private let filterXpc = FilterXPC()

  func establishConnection() async throws {
    try await filterXpc.establishConnection()
  }

  func checkConnectionHealth() async throws {
    try await filterXpc.checkConnectionHealth()
  }

  func requestAck() async throws -> XPC.FilterAck {
    try await filterXpc.requestAck()
  }

  func sendUserRules(manifest: AppIdManifest, keys: [FilterKey]) async throws {
    try await filterXpc.sendUserRules(manifest: manifest, keys: keys)
  }

  func setBlockStreaming(enabled: Bool) async throws {
    try await filterXpc.setBlockStreaming(enabled: enabled)
  }
}
