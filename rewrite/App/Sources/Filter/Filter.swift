import ComposableArchitecture
import Core
import Foundation
import Shared

import os.log // temp

public struct Filter: Reducer {
  public struct State: Equatable, DecisionState {
    public var userKeys: [uid_t: [FilterKey]] = [:]
    public var appIdManifest = AppIdManifest()
    public var exemptUsers: Set<uid_t> = []
    public var suspensions: [uid_t: FilterSuspension] = [:]
    public var appCache: [String: AppDescriptor] = [:]
    public var blockListeners: [uid_t: Date] = [:]
  }

  public enum Action: Equatable {
    case extensionStarted
    case xpc(XPCEvent.Filter)
    case flowBlocked(FilterFlow)
    case cacheAppDescriptor(String, AppDescriptor)
  }

  @Dependency(\.xpc) var xpc
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.date.now) var now

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .extensionStarted:
      return .merge(
        .fireAndForget { [startListener = xpc.startListener] in
          await startListener()
        },

        .publisher {
          xpc.events()
            .map { .xpc($0) }
            .receive(on: mainQueue)
        }
      )

    case .flowBlocked(let flow):
      if let userId = flow.userId, let expiration = state.blockListeners[userId] {
        if expiration < now {
          state.blockListeners[userId] = nil
          return .none
        }
        return .fireAndForget { [sendBlockedRequest = xpc.sendBlockedRequest] in
          _ = try await sendBlockedRequest(userId, flow.blockedRequest)
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

    case .xpc(.receivedAppMessage(.userRules(let userId, let keys, let manifest))):
      state.userKeys[userId] = keys
      state.appIdManifest = manifest
      state.appCache = [:]
      return .none

    case .xpc(.decodingAppMessageDataFailed):
      return .none
    }
  }
}

let FIVE_MINUTES_IN_SECONDS = 60.0 * 5.0