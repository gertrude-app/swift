import ComposableArchitecture
import Core
import Foundation
import TaggedTime

struct FilterFeature: Feature {
  struct State: Equatable {
    var currentSuspensionExpiration: Date?
    var `extension`: FilterExtensionState = .unknown
  }

  enum Action: Equatable, Sendable {
    case receivedState(FilterExtensionState)
  }

  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .receivedState(let extensionState):
        state.extension = extensionState
        return .none
      }
    }
  }

  struct RootReducer: RootReducing {
    @Dependency(\.date.now) var now
    @Dependency(\.device) var device
    @Dependency(\.filterExtension) var filterExtension
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.websocket) var websocket
  }
}

extension FilterFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .adminAuthenticated(.adminWindow(.webview(.suspendFilterClicked(let seconds)))):
      return suspendFilter(for: .init(seconds), with: &state)

    case .websocket(.receivedMessage(.suspendFilter(let seconds, let comment))):
      return .merge(
        suspendFilter(for: seconds, with: &state),
        .run { _ in
          await device.notifyFilterSuspension(resuming: seconds, from: now, with: comment)
        }
      )

    case .heartbeat(.everyMinute):
      if let expiration = state.filter.currentSuspensionExpiration, expiration <= now {
        state.filter.currentSuspensionExpiration = nil
      }
      return .none

    case .adminWindow(.webview(.resumeFilterClicked)), .menuBar(.resumeFilterClicked):
      state.filter.currentSuspensionExpiration = nil
      return handleFilterSuspensionEnded(early: true)

    case .xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(let userId)))
      where userId == device.currentUserId():
      state.filter.currentSuspensionExpiration = nil
      return handleFilterSuspensionEnded(early: false)

    case .adminWindow(.delegate(.healthCheckFilterExtensionState(let filterState))):
      state.filter.extension = filterState
      return .none

    // TODO: test
    case .menuBar(.turnOnFilterClicked),
         .adminWindow(.webview(.startFilterClicked)):
      if !state.filter.extension.installed {
        // TODO: handle install timout, error, etc
        return .run { _ in _ = await filterExtension.install() }
      } else {
        return .run { _ in _ = await filterExtension.start() }
      }
    default:
      return .none
    }
  }

  func suspendFilter(for seconds: Seconds<Int>, with state: inout State) -> Effect<Action> {
    state.filter.currentSuspensionExpiration = now.advanced(by: Double(seconds.rawValue))
    return .run { send in
      _ = await xpc.suspendFilter(seconds)
    }
  }

  // TODO: make cancellable, cancel when new suspension created
  func handleFilterSuspensionEnded(early endedEarly: Bool = false) -> Effect<Action> {
    .run { send in
      if endedEarly { _ = await xpc.endFilterSuspension() }
      try? await websocket.send(.currentFilterState(.on))
      await device.notifyBrowsersQuitting()
      try await mainQueue.sleep(for: .seconds(60))
      await device.quitBrowsers()
    }
  }
}
