import ComposableArchitecture
import Core
import Foundation
import os.log
import Shared

public struct Filter: Reducer {
  public struct State: Equatable, DecisionState {
    public var userKeys: [uid_t: [FilterKey]] = [:]
    public var appIdManifest = AppIdManifest()
    public var exemptUsers: Set<uid_t> = []
    public var suspensions: [uid_t: FilterSuspension] = [:]
    public var appCache: [String: AppDescriptor] = [:]
    public var blockListeners: [uid_t: Date] = [:]
  }

  public enum Action: Equatable, Sendable {
    case extensionStarted
    case xpc(XPCEvent.Filter)
    case flowBlocked(FilterFlow, AppDescriptor)
    case cacheAppDescriptor(String, AppDescriptor)
    case loadedPersistentState(Persistent.State?)
  }

  @Dependency(\.xpc) var xpc
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.date.now) var now
  @Dependency(\.storage) var storage
  @Dependency(\.uuid) var uuid

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    os_log("[G•] filter received action: %{public}@", String(describing: action))
    switch action {
    case .extensionStarted:
      return .merge(
        .run { [startListener = xpc.startListener] _ in
          await startListener()
        },

        .run { [load = storage.loadPersistentState] send in
          await send(.loadedPersistentState(try load()))
        },

        .publisher {
          xpc.events()
            .map { .xpc($0) }
            .receive(on: mainQueue)
        }
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
        if expiration < now {
          state.blockListeners[userId] = nil
          return .none
        }
        return .run { [send = xpc.sendBlockedRequest, uuid, now] _ in
          try await send(userId, flow.blockedRequest(id: uuid(), time: now, app: app))
        }
      }
      return .none

    case .cacheAppDescriptor(let bundleId, let descriptor):
      state.appCache[bundleId] = descriptor
      return .none

    case .xpc(.receivedAppMessage(.setBlockStreaming(true, let userId))):
      state.blockListeners[userId] = now.advanced(by: FIVE_MINUTES_IN_SECONDS)
      return .none

    case .xpc(.receivedAppMessage(.setBlockStreaming(false, let userId))):
      state.blockListeners[userId] = nil
      return .none

    case .xpc(.receivedAppMessage(.disconnectUser(let userId))):
      state.userKeys[userId] = nil
      state.suspensions[userId] = nil
      state.exemptUsers.remove(userId)
      return saving(state.persistent)

    case .xpc(.receivedAppMessage(.endFilterSuspension(let userId))):
      state.suspensions[userId] = nil
      return .none

    case .xpc(.receivedAppMessage(.suspendFilter(let userId, let duration))):
      state.suspensions[userId] = .init(scope: .unrestricted, duration: duration, now: now)
      return .none

    case .xpc(.receivedAppMessage(.userRules(let userId, let keys, let manifest))):
      state.userKeys[userId] = keys
      state.appIdManifest = manifest
      state.appCache = [:]
      return saving(state.persistent)

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

let FIVE_MINUTES_IN_SECONDS = 60.0 * 5.0
