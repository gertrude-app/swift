import AppKit
import ComposableArchitecture
import Foundation

// public, not nested, because it's used in the AppDelegate
public enum ApplicationAction: Equatable, Sendable {
  case didFinishLaunching
  case willSleep
  case didWake
  case willTerminate
  case systemClockOrTimeZoneChanged
  case appLaunched(pid: pid_t)
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
    @Dependency(\.date.now) var now
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
      guard let lastTrustedTimestamp = state.timestamp else { return
        .none
      }
      return .exec { _ in
        if self.network.isConnected() {
          let networkTime = try await self.api.trustedNetworkTimestamp()
          let systemTime = self.now.timeIntervalSince1970
          let currentDelta = networkTime - systemTime
          let expectedDelta = lastTrustedTimestamp.networkSystemDelta
          if abs(currentDelta - expectedDelta) > 200 {
            await self.api.securityEvent(.systemClockOrTimeZoneChanged)
          }
        } else if let boottime = self.device.boottime() {
          // we have no network to get a trusted timestamp, and we've received a system clock change.
          // if the boottime has changed, this is a reasonable indication we can't trust that
          // we could infer the network time by using the current time and our last network/system diff
          // therefore, we're in a situation where it's reasonable to question if a user is
          // attempting to bypass time-based security controls, so notify the parent
          // @see https://developer.apple.com/forums/thread/110044?answerId=337069022#337069022
          let boottimeDelta = boottime.timeIntervalSince1970
            - lastTrustedTimestamp.boottime.timeIntervalSince1970
          if abs(boottimeDelta) > 60 * 30 {
            await self.api.securityEvent(.systemClockOrTimeZoneChanged, "suspicious bootime change")
          }
        }
      }

    case .application(.appLaunched(let pid)):
      guard let blockedApps = state.user.data?.blockedApps, !blockedApps.isEmpty else {
        return .none
      }
      return .exec { _ in
        if let app = NSRunningApplication(processIdentifier: pid),
           blockedApps.blocks(app: app) {
          await self.device.terminateApp(app)
          await self.device.notify(
            "Application blocked",
            "The app “\(app.name ?? "")” is not allowed"
          )
          await self.api.securityEvent(
            .blockedAppLaunchAttempted,
            "app: \(app.name ?? app.bundleIdentifier ?? "")"
          )
        }
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
