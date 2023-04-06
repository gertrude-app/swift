import ComposableArchitecture

// public, not nested, because it's used in the AppDelegate
public enum ApplicationAction: Equatable, Sendable {
  case didFinishLaunching
  case willTerminate
}

enum ApplicationFeature {
  typealias Action = ApplicationAction

  struct RootReducer {
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.backgroundQueue) var bgQueue
    @Dependency(\.storage) var storage
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.filterExtension) var filterExtension
  }
}

extension ApplicationFeature.RootReducer: RootReducing {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .application(.didFinishLaunching):
      return .merge(
        .run { send in
          await send(.loadedPersistentState(try await storage.loadPersistentState()))
          let setupState = await filterExtension.setup()
          await send(.filter(.receivedState(setupState)))
          if setupState == .on {
            _ = await filterXpc.establishConnection()
          }
        },

        .run { send in
          for await _ in bgQueue.timer(interval: .seconds(60 * 30)) {
            await send(.heartbeat)
          }
        }.cancellable(id: HeartbeatCancelId.self),

        .publisher {
          // TODO: when filter goes _TO_ .notInstalled, the NSXPCConnection
          // becomes useless, we should re-create/invalidate it then
          filterExtension.stateChanges()
            .map { .filter(.receivedState($0)) }
            .receive(on: mainQueue)
        },

        .publisher {
          filterXpc.events()
            .map { .receivedXpcEvent($0) }
            .receive(on: mainQueue)
        }
      )

    case .application(.willTerminate):
      return .cancel(id: HeartbeatCancelId.self)

    default:
      return .none
    }
  }
}

extension ApplicationFeature.RootReducer {
  private enum HeartbeatCancelId {}
}
