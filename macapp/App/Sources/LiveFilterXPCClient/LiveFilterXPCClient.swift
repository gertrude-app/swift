import ClientInterfaces
import Core
import Dependencies
import Foundation
import Gertie
import TaggedTime

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
      disconnectUser: { await .init {
        try await xpc.disconnectUser()
      }},
      endFilterSuspension: { await .init {
        try await xpc.endFilterSuspension()
      }},
      requestAck: { await .init {
        try await xpc.requestAck()
      }},
      requestExemptUserIds: { await .init {
        try await xpc.requestExemptUserIds()
      }},
      sendDeleteAllStoredState: { await .init {
        try await xpc.sendDeleteAllStoredState()
      }},
      sendUserRules: { manifest, keys in await .init {
        try await xpc.sendUserRules(manifest: manifest, keys: keys)
      }},
      setBlockStreaming: { enabled in await .init {
        try await xpc.setBlockStreaming(enabled: enabled)
      }},
      setUserExemption: { userId, enabled in await .init {
        try await xpc.setUserExemption(userId: userId, enabled: enabled)
      }},
      suspendFilter: { duration in await .init {
        try await xpc.suspendFilter(for: duration)
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
    try await self.filterXpc.establishConnection()
  }

  func checkConnectionHealth() async throws {
    try await self.filterXpc.checkConnectionHealth()
  }

  func endFilterSuspension() async throws {
    try await self.filterXpc.endFilterSuspension()
  }

  func suspendFilter(for duration: Seconds<Int>) async throws {
    try await self.filterXpc.suspendFilter(for: duration)
  }

  func disconnectUser() async throws {
    try await self.filterXpc.disconnectUser()
  }

  func requestAck() async throws -> XPC.FilterAck {
    try await self.filterXpc.requestAck()
  }

  func sendUserRules(manifest: AppIdManifest, keys: [FilterKey]) async throws {
    try await self.filterXpc.sendUserRules(manifest: manifest, keys: keys)
  }

  func setBlockStreaming(enabled: Bool) async throws {
    try await self.filterXpc.setBlockStreaming(enabled: enabled)
  }

  func setUserExemption(userId: uid_t, enabled: Bool) async throws {
    try await self.filterXpc.setUserExemption(userId: userId, enabled: enabled)
  }

  func requestExemptUserIds() async throws -> [uid_t] {
    try await self.filterXpc.requestExemptUserIds()
  }

  func sendDeleteAllStoredState() async throws {
    try await self.filterXpc.sendDeleteAllStoredState()
  }
}
