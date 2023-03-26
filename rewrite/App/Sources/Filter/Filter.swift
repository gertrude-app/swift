import ComposableArchitecture

struct Filter: Reducer, Sendable {
  struct State: Equatable, Sendable {}

  enum Action: Equatable, Sendable {
    case extensionStarted
  }

  @Dependency(\.xpc) var xpc

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .extensionStarted:
      return .fireAndForget {
        await xpc.startListener()
        while true {
          try? await Task.sleep(nanoseconds: 3_000_000_000)
          // just testing filter -> app comm
          try? await xpc.sendUuid()
        }
      }
    }
  }
}
