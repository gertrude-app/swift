import Combine
import Core
import Dependencies
import Foundation
import Gertie

struct XPCClient: Sendable {
  var notifyFilterSuspensionEnded: @Sendable (uid_t) async throws -> Void
  var startListener: @Sendable () async -> Void
  var stopListener: @Sendable () async -> Void
  var sendBlockedRequest: @Sendable (uid_t, BlockedRequest) async throws -> Void
  var sendLogs: @Sendable (FilterLogs) async throws -> Void
  var events: @Sendable () -> AnyPublisher<XPCEvent.Filter, Never>
}

extension XPCClient: DependencyKey {
  static var liveValue: Self {
    let manager = ThreadSafeXPCManager()
    return .init(
      notifyFilterSuspensionEnded: { userId in
        try await manager.notifyFilterSuspensionEnded(for: userId)
      },
      startListener: {
        await manager.startListener()
      },
      stopListener: {
        await manager.stopListener()
      },
      sendBlockedRequest: { userId, request in
        try await manager.sendBlockedRequest(request, userId: userId)
      },
      sendLogs: { logs in
        try await manager.sendLogs(logs)
      },
      events: {
        xpcEventSubject.withValue { subject in
          Move(subject.eraseToAnyPublisher())
        }.consume()
      },
    )
  }
}

extension XPCClient: TestDependencyKey {
  static let testValue = Self(
    notifyFilterSuspensionEnded: unimplemented("XPCClient.notifyFilterSuspensionEnded"),
    startListener: unimplemented("XPCClient.startListener"),
    stopListener: unimplemented("XPCClient.stopListener"),
    sendBlockedRequest: unimplemented("XPCClient.sendBlockedRequest"),
    sendLogs: unimplemented("XPCClient.sendLogs"),
    events: unimplemented("XPCClient.events", placeholder: AnyPublisher(Empty())),
  )
  static let mock = Self(
    notifyFilterSuspensionEnded: { _ in },
    startListener: {},
    stopListener: {},
    sendBlockedRequest: { _, _ in },
    sendLogs: { _ in },
    events: { Empty().eraseToAnyPublisher() },
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
    self.manager.startListener()
  }

  func stopListener() {
    self.manager.stopListener()
  }

  func sendBlockedRequest(_ request: BlockedRequest, userId: uid_t) async throws {
    try await self.manager.sendBlockedRequest(request, userId: userId)
  }

  func notifyFilterSuspensionEnded(for userId: uid_t) async throws {
    try await self.manager.notifyFilterSuspensionEnded(for: userId)
  }

  func sendLogs(_ logs: FilterLogs) async throws {
    try await self.manager.sendLogs(logs)
  }
}

let xpcEventSubject = Mutex(PassthroughSubject<XPCEvent.Filter, Never>())
