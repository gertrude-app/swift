import ComposableArchitecture

// public, not nested, because it's used in the AppDelegate
public enum ApplicationAction: Equatable, Sendable {
  case didFinishLaunching
  case willSleep
  case didWake
  case willTerminate
}

enum ApplicationFeature {
  typealias Action = ApplicationAction

  struct RootReducer {
    @Dependency(\.app) var app
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.backgroundQueue) var bgQueue
    @Dependency(\.storage) var storage
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.filterExtension) var filterExtension
    @Dependency(\.websocket) var websocket
  }
}

extension ApplicationFeature.RootReducer: RootReducing {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .application(.didFinishLaunching):
      return .merge(
        .run { send in
          await send(.loadedPersistentState(try await storage.loadPersistentState()))
        },

        .run { send in
          try await bgQueue.sleep(for: .milliseconds(5)) // <- unit test determinism
          let setupState = await filterExtension.setup()
          await send(.filter(.receivedState(setupState)))
          if setupState.installed {
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

        .run { _ in
          if await app.isLaunchAtLoginEnabled() == false {
            await app.enableLaunchAtLogin()
          }
        },

        .publisher {
          filterExtension.stateChanges()
            .map { .filter(.receivedState($0)) }
            .receive(on: mainQueue)
        },

        .publisher {
          filterXpc.events()
            .map { .xpc($0) }
            .receive(on: mainQueue)
        },

        .publisher {
          websocket.receive()
            .map { .websocket(.receivedMessage($0)) }
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
    if tick % 5 == 0 {
      intervals.append(.everyFiveMinutes)
    }
    if tick % 20 == 0 {
      intervals.append(.everyTwentyMinutes)
    }
    if tick % 360 == 0 {
      intervals.append(.everySixHours)
    }
    return intervals
  }
}
