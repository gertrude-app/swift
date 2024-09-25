import ComposableArchitecture
import Foundation

// public, not nested, because it's used in the AppDelegate
public enum ApplicationAction: Equatable, Sendable {
  case didFinishLaunching
  case willSleep
  case didWake
  case willTerminate
  case systemClockOrTimeZoneChanged
}

enum ApplicationFeature {
  typealias Action = ApplicationAction

  struct RootReducer {
    typealias State = AppReducer.State
    typealias Action = AppReducer.Action
    @Dependency(\.api) var api
    @Dependency(\.app) var app
    @Dependency(\.backgroundQueue) var bgQueue
    @Dependency(\.device) var device
    @Dependency(\.storage) var storage
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.filterExtension) var filterExtension
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.network) var network
    @Dependency(\.userDefaults) var userDefaults
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
          let state = try await self.storage.loadPersistentState()
          await send(.loadedPersistentState(state))
          if let deviceId = state?.user?.deviceId {
            await self.api.securityEvent(deviceId: deviceId, event: .appLaunched)
          }
        },

        .exec { send in
          let setupState = await self.filterExtension.setup()
          await send(.filter(.receivedState(setupState)))
          if setupState.installed {
            _ = await filterXpc.establishConnection()
          }
        },

        .publisher {
          self.filterExtension.stateChanges()
            .map { .filter(.receivedState($0)) }
            .receive(on: self.mainQueue)
        },

        .publisher {
          self.filterXpc.events()
            .map { .xpc($0) }
            .receive(on: self.mainQueue)
        }
      )

    case .heartbeat(.everyFiveMinutes):
      guard self.network.isConnected() else {
        return .none
      }
      return .exec { _ in
        guard let bufferedSecurityEvents = try? self.userDefaults.loadJson(
          at: .bufferedSecurityEventsKey,
          decoding: [BufferedSecurityEvent].self
        ) else { return }
        self.userDefaults.remove(.bufferedSecurityEventsKey)
        for buffered in bufferedSecurityEvents {
          await self.api.logSecurityEvent(
            .init(
              deviceId: buffered.deviceId,
              event: buffered.event.rawValue,
              detail: buffered.detail
            ),
            buffered.userToken
          )
        }
      }

    case .application(.systemClockOrTimeZoneChanged):
      return .exec { _ in
        await self.api.securityEvent(.systemClockOrTimeZoneChanged)
      }

    case .application(.willTerminate):
      return .merge(
        .cancel(id: AppReducer.CancelId.heartbeatInterval),
        .cancel(id: AppReducer.CancelId.websocketMessages),
        .exec { _ in await self.app.stopRelaunchWatcher() }
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
