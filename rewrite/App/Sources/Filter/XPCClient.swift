import Combine
import Core
import Dependencies

struct XPCClient: Sendable {
  var startListener: @Sendable () async -> Void
  var sendUuid: @Sendable () async throws -> Void
  var events: @Sendable () -> AnyPublisher<XPCEvent.Filter, Never>
}

extension XPCClient: DependencyKey {
  static var liveValue: Self {
    let manager = ThreadSafeXPCManager()
    return .init(
      startListener: { await manager.startListener() },
      sendUuid: { try await manager.sendUuid() },
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
    sendUuid: {},
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

  func sendUuid() async throws {
    try await manager.sendUuid()
  }
}

internal let xpcEventSubject = Mutex(PassthroughSubject<XPCEvent.Filter, Never>())
