import Combine
import Core
import Dependencies
import Foundation

struct XPCClient: Sendable {
  var startListener: @Sendable () async -> Void
  var sendBlockedRequest: @Sendable (uid_t, BlockedRequest) async throws -> Void
  var events: @Sendable () -> AnyPublisher<XPCEvent.Filter, Never>
}

extension XPCClient: DependencyKey {
  static var liveValue: Self {
    let manager = ThreadSafeXPCManager()
    return .init(
      startListener: {
        await manager.startListener()
      },
      sendBlockedRequest: { userId, request in
        try await manager.sendBlockedRequest(request, userId: userId)
      },
      events: {
        xpcEventSubject.withValue { subject in
          Move(subject.eraseToAnyPublisher())
        }.consume()
      }
    )
  }
}

extension XPCClient: TestDependencyKey {
  static let testValue = Self(
    startListener: {},
    sendBlockedRequest: { _, _ in },
    events: { Empty().eraseToAnyPublisher() }
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

  func sendBlockedRequest(_ request: BlockedRequest, userId: uid_t) async throws {
    try await manager.sendBlockedRequest(request, userId: userId)
  }
}

internal let xpcEventSubject = Mutex(PassthroughSubject<XPCEvent.Filter, Never>())
