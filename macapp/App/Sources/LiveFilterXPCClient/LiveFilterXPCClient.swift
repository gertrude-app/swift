import ClientInterfaces
import Core
import Dependencies
import Foundation
import Gertie
import TaggedTime

extension FilterXPCClient: @retroactive DependencyKey {
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
      endDowntimePause: { await .init {
        try await xpc.endDowntimePause()
      }},
      pauseDowntime: { expiration in await .init {
        try await xpc.pauseDowntime(until: expiration)
      }},
      requestAck: { await .init {
        try await xpc.requestAck()
      }},
      requestUserTypes: { await .init {
        try await xpc.requestUserTypes()
      }},
      sendAlive: { await .init {
        let success = try await xpc.sendAlive()
        if !success {
          await send(urlMessage: .alive(getuid()))
          _ = try await xpc.requestAck()
        }
        return success
      }},
      sendDeleteAllStoredState: { await .init {
        try await xpc.sendDeleteAllStoredState()
      }},
      sendURLMessage: send(urlMessage:),
      sendUserRules: { manifest, keychains, downtime in await .init {
        try await xpc.sendUserRules(manifest: manifest, keychains: keychains, downtime: downtime)
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

  func pauseDowntime(until expiration: Date) async throws {
    try await self.filterXpc.pauseDowntime(until: expiration)
  }

  func endDowntimePause() async throws {
    try await self.filterXpc.endDowntimePause()
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

  func sendAlive() async throws -> Bool {
    try await self.filterXpc.sendAlive()
  }

  func sendUserRules(
    manifest: AppIdManifest,
    keychains: [RuleKeychain],
    downtime: Downtime?
  ) async throws {
    try await self.filterXpc.sendUserRules(
      manifest: manifest,
      keychains: keychains,
      downtime: downtime
    )
  }

  func setBlockStreaming(enabled: Bool) async throws {
    try await self.filterXpc.setBlockStreaming(enabled: enabled)
  }

  func setUserExemption(userId: uid_t, enabled: Bool) async throws {
    try await self.filterXpc.setUserExemption(userId: userId, enabled: enabled)
  }

  func requestUserTypes() async throws -> FilterUserTypes {
    try await self.filterXpc.requestUserTypes()
  }

  func sendDeleteAllStoredState() async throws {
    try await self.filterXpc.sendDeleteAllStoredState()
  }
}

// helpers

@Sendable
private func send(urlMessage: XPC.URLMessage) async {
  var request = URLRequest(url: urlMessage.url)
  request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
  request.timeoutInterval = 2
  _ = try? await URLSession.shared.data(for: request)
}
