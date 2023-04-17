import ComposableArchitecture
import Core
import Foundation
import Shared

public struct Filter: Reducer {
  public struct State: Equatable, DecisionState {
    public var userKeys: [uid_t: [FilterKey]] = [:]
    public var appIdManifest = AppIdManifest()
    public var exemptUsers: Set<uid_t> = []
    public var suspensions: [uid_t: FilterSuspension] = [:]
    public var appCache: [String: AppDescriptor] = [:]
  }

  public enum Action: Equatable {
    case extensionStarted
    case receivedXpcEvent(XPCEvent.Filter)
    case cacheAppDescriptor(String, AppDescriptor)
  }

  @Dependency(\.xpc) var xpc
  @Dependency(\.mainQueue) var mainQueue

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .extensionStarted:
      return .merge(
        .fireAndForget { [startListener = xpc.startListener] in
          await startListener()
        },

        .publisher {
          xpc.events()
            .map { .receivedXpcEvent($0) }
            .receive(on: mainQueue)
        }
      )

    case .cacheAppDescriptor(let bundleId, let descriptor):
      state.appCache[bundleId] = descriptor
      return .none

    case .receivedXpcEvent(.receivedAppMessage(.userRules(let userId, let keys, let manifest))):
      state.userKeys[userId] = keys
      state.appIdManifest = manifest
      state.appCache = [:]
      return .none

    case .receivedXpcEvent(.decodingAppMessageDataFailed):
      return .none
    }
  }
}
