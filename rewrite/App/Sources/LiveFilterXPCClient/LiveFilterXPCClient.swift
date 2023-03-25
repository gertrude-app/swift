import Core
import Dependencies
import Models

extension FilterXPCClient: DependencyKey {
  public static var liveValue: Self {
    let xpc = ThreadSafe(FilterXPC())
    return .init(
      establishConnection: { await .init {
        try await xpc.value.establishConnection()
      }},
      isConnectionHealthy: { await .init {
        try await xpc.value.isConnectionHealthy()
      }},
      events: { fatalError() }
    )
  }
}
