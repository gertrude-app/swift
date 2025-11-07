import ComposableArchitecture
import Core
import Foundation
import Gertie
import os.log

public struct Filter: Reducer, Sendable {
  public struct State: Equatable, DecisionState {
    public var userKeychains: [uid_t: [RuleKeychain]] = [:]
    public var userDowntime: [uid_t: Downtime] = [:]
    public var appIdManifest = AppIdManifest()
    public var exemptUsers: Set<uid_t> = []
    public var suspensions: [uid_t: FilterSuspension] = [:]
    public var appCache: [String: AppDescriptor] = [:]
    public var blockListeners: [uid_t: Date] = [:]
    public var macappsAliveUntil: [uid_t: Date] = [:]
    public var logs: FilterLogs = .init(bundleIds: [:], events: [:])

    public init() {}
  }

  public enum Action: Equatable, Sendable {
    case extensionStarted
    case extensionStopping
    case xpc(XPCEvent.Filter)
    case urlMessage(XPC.URLMessage)
    case flowBlocked(FilterFlow, AppDescriptor)
    case cacheAppDescriptor(String, AppDescriptor)
    case loadedPersistentState(Persistent.State?)
    case suspensionTimerEnded(uid_t)
    case staleSuspensionFound(uid_t)
    case logAppRequest(String)
    case logEvent(FilterLogs.Event)
    case heartbeat
  }

  @Dependency(\.xpc) var xpc
  @Dependency(\.filterExtension) var filterExtension
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.date.now) var now
  @Dependency(\.storage) var storage
  @Dependency(\.uuid) var uuid

  private enum CancelId: Hashable {
    case heartbeat
    case suspensionTimer(for: uid_t)
  }

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .cacheAppDescriptor, .logAppRequest:
      break
    default:
      os_log(
        "[G•] FILTER (%{public}@) received action: %{public}@",
        self.filterExtension.version(),
        String(describing: action),
      )
    }

    switch action {
    case .extensionStarted:
      return .merge(
        .run { _ in
          await self.xpc.startListener()
        },

        .run { [load = storage.loadPersistentState] send in
          try await send(.loadedPersistentState(load()))
        },

        .run { send in
          for await _ in self.mainQueue.timer(interval: .seconds(60)) {
            await send(.heartbeat)
          }
        }.cancellable(id: CancelId.heartbeat, cancelInFlight: true),

        .publisher {
          self.xpc.events()
            .map { .xpc($0) }
            .receive(on: self.mainQueue)
        },
      )

    case .extensionStopping:
      return .merge(
        .cancel(id: CancelId.heartbeat),
        .run { _ in await self.xpc.stopListener() },
      )

    case .loadedPersistentState(.some(let persisted)):
      state.userKeychains = persisted.userKeychains
      state.appIdManifest = persisted.appIdManifest
      state.exemptUsers = persisted.exemptUsers
      return .none

    case .loadedPersistentState(.none):
      return .none

    case .flowBlocked(let flow, let app):
      if let userId = flow.userId, let expiration = state.blockListeners[userId] {
        if expiration < self.now {
          state.blockListeners[userId] = nil
          return .none
        }
        return .run { _ in
          let blockedReq = flow.blockedRequest(id: self.uuid(), time: self.now, app: app)
          try await self.xpc.sendBlockedRequest(userId, blockedReq)
        }
      }
      return .none

    case .heartbeat:
      var effect: Effect<Action> = .none
      for (userId, suspension) in state.suspensions {
        // 5 second cushion prevents race between heartbeat and expiration timer
        // we want the expiration timer to do the work, this is only a failsafe
        if suspension.expiresAt < self.now.advanced(by: .seconds(-5)) {
          effect = effect.merge(with: .run { send in
            await send(.staleSuspensionFound(userId))
          })
        }
      }

      for (userId, expiration) in state.macappsAliveUntil {
        if expiration < self.now {
          state.macappsAliveUntil[userId] = nil
        }
      }

      for userId in state.userDowntime.keys {
        if let pauseExpiry = state.userDowntime[userId]?.pausedUntil, pauseExpiry < self.now {
          state.userDowntime[userId]?.pausedUntil = nil
        }
      }

      // enable additional debug logging when we're streaming blocks
      // which is currently our simple proxy for additional filter logging
      // until we expose some sort of app -> extension message to log verbose
      if !state.blockListeners.isEmpty {
        os_log("[D•] FILTER state in heartbeat: %{public}@", "\(state.debug)")
      }

      if state.logs.count() >= 500 {
        let logs = state.logs
        state.logs = .init(bundleIds: [:], events: [:])
        effect = effect.merge(with: .run { _ in
          try? await self.xpc.sendLogs(logs)
        })
      }

      return effect

    case .suspensionTimerEnded(let userId):
      state.suspensions[userId] = nil
      return .run { _ in try await self.xpc.notifyFilterSuspensionEnded(userId) }

    case .staleSuspensionFound(let userId):
      state.suspensions[userId] = nil
      return .merge(
        .cancel(id: CancelId.suspensionTimer(for: userId)),
        .run { _ in try await self.xpc.notifyFilterSuspensionEnded(userId) },
      )

    case .cacheAppDescriptor("", _):
      return .none // don't cache empty bundle id

    case .cacheAppDescriptor(let bundleId, let descriptor):
      state.appCache[bundleId] = descriptor
      return .none

    case .logAppRequest(let bundleId):
      state.logs.bundleIds[bundleId, default: 0] += 1
      return .none

    case .logEvent(let event):
      state.logs.log(event: event)
      return .none

    case .xpc(.receivedAppMessage(.setBlockStreaming(true, let userId))):
      state.recordAppActivity(from: userId)
      state.blockListeners[userId] = self.now + .minutes(5)
      os_log("[D•] FILTER state start streaming: %{public}@", "\(state.debug)")
      return .none

    case .xpc(.receivedAppMessage(.setBlockStreaming(false, let userId))):
      state.recordAppActivity(from: userId)
      state.blockListeners[userId] = nil
      return .none

    case .xpc(.receivedAppMessage(.disconnectUser(let userId))):
      state.userKeychains[userId] = nil
      state.suspensions[userId] = nil
      state.exemptUsers.remove(userId)
      return self.saving(state.persistent)

    case .xpc(.receivedAppMessage(.endFilterSuspension(let userId))):
      state.recordAppActivity(from: userId)
      state.suspensions[userId] = nil
      return .cancel(id: CancelId.suspensionTimer(for: userId))

    case .xpc(.receivedAppMessage(.suspendFilter(let userId, let duration))):
      state.recordAppActivity(from: userId)
      state.suspensions[userId] = .init(
        scope: .unrestricted,
        duration: duration,
        now: self.now,
      )
      return .run { send in
        // NB: this sleep pauses (and thus becomes incorrect) when the computer is asleep
        // ideally we should use ContinuousClock instead, but it's not available for our targets
        // so we check for stale suspensions in the heartbeat, cancelling the timer
        try await self.mainQueue.sleep(for: .seconds(duration.rawValue))
        await send(.suspensionTimerEnded(userId))
      }.cancellable(id: CancelId.suspensionTimer(for: userId), cancelInFlight: true)

    case .xpc(.receivedAppMessage(.userRules(
      let userId,
      let keychains,
      let downtime,
      let manifest,
    ))):
      state.recordAppActivity(from: userId)
      if !keychains.isEmpty {
        state.userKeychains[userId] = keychains
        state.exemptUsers.remove(userId)
      }
      state.appIdManifest = manifest
      state.appCache = [:]
      state.userDowntime[userId] = downtime
      return self.saving(state.persistent)

    case .xpc(.receivedAppMessage(.setUserExemption(let userId, let enabled))):
      if enabled {
        state.exemptUsers.insert(userId)
      } else {
        state.exemptUsers.remove(userId)
      }
      return self.saving(state.persistent)

    case .xpc(.receivedAppMessage(.deleteAllStoredState)):
      state = .init()
      return .run { _ in
        await self.storage.deleteAll()
      }

    case .xpc(.receivedAppMessage(.pauseDowntime(let userId, let expiration))):
      state.recordAppActivity(from: userId)
      state.userDowntime[userId]?.pausedUntil = expiration
      return .none

    case .xpc(.receivedAppMessage(.endDowntimePause(let userId))):
      state.recordAppActivity(from: userId)
      state.userDowntime[userId]?.pausedUntil = nil
      return .none

    case .xpc(.receivedAppMessage(.macappAlive(let userId))),
         .urlMessage(.alive(let userId)):
      state.recordAppActivity(from: userId)
      return .none

    case .xpc(.decodingAppMessageDataFailed):
      return .none

    case .urlMessage(.restartListener):
      // not implemented yet
      return .none
    }
  }

  func saving(_ state: Persistent.State) -> Effect<Action> {
    .run { [save = storage.savePersistentState] _ in
      try await save(state)
    }
  }
}

public extension Filter.State {
  mutating func recordAppActivity(from userId: uid_t) {
    @Dependency(\.date.now) var now
    self.macappsAliveUntil[userId] = now + .seconds(150)
  }
}

public extension Filter.State {
  struct Debug {
    public var userKeys: [uid_t: Int] = [:]
    public var numAppsInManifest: Int
    public var exemptUsers: Set<uid_t> = []
    public var suspensions: [uid_t: FilterSuspension] = [:]
    public var numAppsInCache: Int
    public var blockListeners: [uid_t: Date] = [:]
    public var userDowntime: [uid_t: Downtime] = [:]
  }

  var debug: Debug {
    .init(
      userKeys: self.userKeychains.reduce(into: [:]) { acc, item in
        let (userId, keychains) = (item.key, item.value)
        acc[userId] = keychains.numKeys
      },
      numAppsInManifest: self.appIdManifest.apps.count,
      exemptUsers: self.exemptUsers,
      suspensions: self.suspensions,
      numAppsInCache: self.appCache.count,
      blockListeners: self.blockListeners,
      userDowntime: self.userDowntime,
    )
  }
}

#if DEBUG
  import Darwin

  func eprint(_ items: Any...) {
    let s = items.map { "\($0)" }.joined(separator: " ")
    fputs(s + "\n", stderr)
    fflush(stderr)
  }
#endif
