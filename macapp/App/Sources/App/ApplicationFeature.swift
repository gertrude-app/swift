import ComposableArchitecture
import Foundation

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
    typealias State = AppReducer.State
    typealias Action = AppReducer.Action
    @Dependency(\.app) var app
    @Dependency(\.backgroundQueue) var bgQueue
    @Dependency(\.device) var device
    @Dependency(\.storage) var storage
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.filterExtension) var filterExtension
    @Dependency(\.mainQueue) var mainQueue
  }
}

extension ApplicationFeature.RootReducer: RootReducing {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .application(.didFinishLaunching):
      return .merge(
        .exec { send in
          #if DEBUG
            // uncomment to test ONBOARDING
            // if ProcessInfo.processInfo.environment["SWIFT_DETERMINISTIC_HASHING"] == nil {
            //   await storage.deleteAll()
            // }
          #endif
          await send(.loadedPersistentState(try await storage.loadPersistentState()))
        },

        .exec { send in
          let setupState = await filterExtension.setup()
          await send(.filter(.receivedState(setupState)))
          if setupState.installed {
            _ = await filterXpc.establishConnection()
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
        }
      )

    case .application(.willTerminate):
      return .merge(
        .cancel(id: AppReducer.CancelId.heartbeatInterval),
        .cancel(id: AppReducer.CancelId.websocketMessages),
        .exec { _ in await app.stopRelaunchWatcher() }
      )

    default:
      return .none
    }
  }
}

func heartbeatIntervals(for tick: Int) -> [HeartbeatInterval] {
  var intervals: [HeartbeatInterval] = [.everyMinute]
  if tick % 5 == 0 {
    intervals.append(.everyFiveMinutes)
  }
  if tick % 20 == 0 {
    intervals.append(.everyTwentyMinutes)
  }
  if tick % 60 == 0 {
    intervals.append(.everyHour)
  }
  if tick % 360 == 0 {
    intervals.append(.everySixHours)
  }
  return intervals
}
