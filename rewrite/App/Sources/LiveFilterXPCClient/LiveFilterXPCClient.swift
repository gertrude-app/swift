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
      isConnectionHealthy: { await .init {
        try await xpc.isConnectionHealthy()
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

  func isConnectionHealthy() async throws {
    try await filterXpc.isConnectionHealthy()
  }

  func sendUserRules(manifest: AppIdManifest, keys: [FilterKey]) async throws {
    try await filterXpc.sendUserRules(manifest: manifest, keys: keys)
  }

  func setBlockStreaming(enabled: Bool) async throws {
    try await filterXpc.setBlockStreaming(enabled: enabled)
  }
}
