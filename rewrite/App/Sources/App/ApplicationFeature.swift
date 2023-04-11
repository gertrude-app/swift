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
          var numTicks = 0
          for await _ in bgQueue.timer(interval: .seconds(60)) {
            numTicks += 1
            for interval in heartbeatIntervals(for: numTicks) {
              await send(.heartbeat(interval))
            }
          }
        }.cancellable(id: Heartbeat.CancelId.self),

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
      return .cancel(id: Heartbeat.CancelId.self)

    default:
      return .none
    }
  }

  func heartbeatIntervals(for tick: Int) -> [Heartbeat.Interval] {
    var intervals: [Heartbeat.Interval] = [.everyMinute]
    if tick % 20 == 0 {
      intervals.append(.everyTwentyMinutes)
    }
    return intervals
  }
}
