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
  }

  public enum Action: Equatable {
    case extensionStarted
    case receivedXpcEvent(XPCEvent.Filter)
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

    case .receivedXpcEvent(.receivedAppMessage(.userRules(let userId, let keys, let manifest))):
      state.userKeys[userId] = keys
      state.appIdManifest = manifest
      return .none

    case .receivedXpcEvent(.decodingAppMessageDataFailed):
      return .none
    }
  }
}
