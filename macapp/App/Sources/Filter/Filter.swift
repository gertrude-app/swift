import ComposableArchitecture
import Core
import Foundation
import Gertie
import os.log

public struct Filter: Reducer, Sendable {
  public struct State: Equatable, DecisionState {
    public var userKeys: [uid_t: [FilterKey]] = [:]
    public var userDowntime: [uid_t: PlainTimeWindow] = [:]
    public var appIdManifest = AppIdManifest()
    public var exemptUsers: Set<uid_t> = []
    public var suspensions: [uid_t: FilterSuspension] = [:]
    public var appCache: [String: AppDescriptor] = [:]
    public var blockListeners: [uid_t: Date] = [:]
  }

  public enum Action: Equatable, Sendable {
    case extensionStarted
    case extensionStopping
    case xpc(XPCEvent.Filter)
    case flowBlocked(FilterFlow, AppDescriptor)
    case cacheAppDescriptor(String, AppDescriptor)
    case loadedPersistentState(Persistent.State?)
    case suspensionTimerEnded(uid_t)
    case staleSuspensionFound(uid_t)
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
    case .cacheAppDescriptor:
      break
    default:
      os_log(
        "[G•] FILTER (%{public}@) received action: %{public}@",
        self.filterExtension.version(),
        String(describing: action)
      )
    }

    switch action {
    case .extensionStarted:
      return .merge(
        .run { [startListener = xpc.startListener] _ in
          await startListener()
        },

        .run { [load = storage.loadPersistentState] send in
          await send(.loadedPersistentState(try load()))
        },

        .run { send in
          for await _ in mainQueue.timer(interval: .seconds(60)) {
            await send(.heartbeat)
          }
        }.cancellable(id: CancelId.heartbeat, cancelInFlight: true),

        .publisher {
          xpc.events()
            .map { .xpc($0) }
            .receive(on: mainQueue)
        }
      )

    case .extensionStopping:
      return .merge(
        .cancel(id: CancelId.heartbeat),
        .run { _ in await xpc.stopListener() }
      )

    case .loadedPersistentState(.some(let persisted)):
      state.userKeys = persisted.userKeys
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
        return .run { [send = xpc.sendBlockedRequest, uuid, now] _ in
          try await send(userId, flow.blockedRequest(id: uuid(), time: now, app: app))
        }
      }
      return .none

    case .heartbeat:
      var expiredSuspensionUserIds: [uid_t] = []
      for (userId, suspension) in state.suspensions {
        // 5 second cushion prevents race between heartbeat and expiration timer
        // we want the expiration timer to do the work, this is only a failsafe
        if suspension.expiresAt < self.now.advanced(by: .seconds(-5)) {
          expiredSuspensionUserIds.append(userId)
        }
      }

      // enable additional debug logging when we're streaming blocks
      // which is currently our simple proxy for additional filter logging
      // until we expose some sort of app -> extension message to log verbose
      if !state.blockListeners.isEmpty {
        os_log("[D•] FILTER state in heartbeat: %{public}@", "\(state.debug)")
      }

      return expiredSuspensionUserIds.isEmpty
        ? .none
        : .run { [expiredSuspensionUserIds] send in
          for userId in expiredSuspensionUserIds {
            await send(.staleSuspensionFound(userId))
          }
        }

    case .suspensionTimerEnded(let userId):
      state.suspensions[userId] = nil
      return .run { _ in try await xpc.notifyFilterSuspensionEnded(userId) }

    case .staleSuspensionFound(let userId):
      state.suspensions[userId] = nil
      return .merge(
        .cancel(id: CancelId.suspensionTimer(for: userId)),
        .run { _ in try await xpc.notifyFilterSuspensionEnded(userId) }
      )

    case .cacheAppDescriptor("", _):
      return .none // don't cache empty bundle id

    case .cacheAppDescriptor(let bundleId, let descriptor):
      state.appCache[bundleId] = descriptor
      return .none

    case .xpc(.receivedAppMessage(.setBlockStreaming(true, let userId))):
      state.blockListeners[userId] = self.now.advanced(by: FIVE_MINUTES_IN_SECONDS)
      os_log("[D•] FILTER state start streaming: %{public}@", "\(state.debug)")
      return .none

    case .xpc(.receivedAppMessage(.setBlockStreaming(false, let userId))):
      state.blockListeners[userId] = nil
      return .none

    case .xpc(.receivedAppMessage(.disconnectUser(let userId))):
      state.userKeys[userId] = nil
      state.suspensions[userId] = nil
      state.exemptUsers.remove(userId)
      return self.saving(state.persistent)

    case .xpc(.receivedAppMessage(.endFilterSuspension(let userId))):
      state.suspensions[userId] = nil
      return .cancel(id: CancelId.suspensionTimer(for: userId))

    case .xpc(.receivedAppMessage(.suspendFilter(let userId, let duration))):
      state.suspensions[userId] = .init(
        scope: .unrestricted,
        duration: duration,
        now: self.now
      )
      return .run { send in
        // NB: this sleep pauses (and thus becomes incorrect) when the computer is asleep
        // ideally we should use ContinuousClock instead, but it's not available for our targets
        // so we check for stale suspensions in the heartbeat, cancelling the timer
        try await mainQueue.sleep(for: .seconds(duration.rawValue))
        await send(.suspensionTimerEnded(userId))
      }.cancellable(id: CancelId.suspensionTimer(for: userId), cancelInFlight: true)

    case .xpc(.receivedAppMessage(.userRules(let userId, let keys, let downtime, let manifest))):
      if !keys.isEmpty {
        state.userKeys[userId] = keys
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
        await storage.deleteAll()
      }

    case .xpc(.decodingAppMessageDataFailed):
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
  struct Debug {
    public var userKeys: [uid_t: Int] = [:]
    public var numAppsInManifest: Int
    public var exemptUsers: Set<uid_t> = []
    public var suspensions: [uid_t: FilterSuspension] = [:]
    public var numAppsInCache: Int
    public var blockListeners: [uid_t: Date] = [:]
  }

  var debug: Debug {
    .init(
      userKeys: userKeys.reduce(into: [:]) { acc, item in
        acc[item.key] = item.value.count
      },
      numAppsInManifest: appIdManifest.apps.count,
      exemptUsers: exemptUsers,
      suspensions: suspensions,
      numAppsInCache: appCache.count,
      blockListeners: blockListeners
    )
  }
}

let FIVE_MINUTES_IN_SECONDS = 60.0 * 5.0

#if DEBUG
  import Darwin

  func eprint(_ items: Any...) {
    let s = items.map { "\($0)" }.joined(separator: " ")
    fputs(s + "\n", stderr)
    fflush(stderr)
  }
#endif
