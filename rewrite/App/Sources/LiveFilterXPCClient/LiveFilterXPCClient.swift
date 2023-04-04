import Core
import Dependencies
import Models

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
}
