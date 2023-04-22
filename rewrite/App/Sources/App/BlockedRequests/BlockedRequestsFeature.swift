import ComposableArchitecture
import Core
import Foundation
import Shared

struct BlockedRequestsFeature: Feature {
  struct State: Equatable {
    var windowOpen = false
    var requests: [BlockedRequest] = []
    var filterText = ""
    var tcpOnly = true
    var unlockRequest = RequestState<String>.idle
  }

  enum Action: Equatable, Sendable, Decodable {
    case openWindow
    case closeWindow
    case filterTextUpdated(text: String)
    case unlockRequestSubmitted(ids: [UUID])
    case tcpOnlyToggled
    case clearRequestsClicked
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.filterXpc) var filterXpc

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .openWindow:
        state.windowOpen = true
        return restartBlockStreaming()
      case .closeWindow:
        state.windowOpen = false
        return endBlockStreaming()
      case .filterTextUpdated(let text):
        state.filterText = text
        return restartBlockStreaming()
      case .tcpOnlyToggled:
        state.tcpOnly.toggle()
        return restartBlockStreaming()
      case .clearRequestsClicked:
        state.requests = []
        return restartBlockStreaming()
      case .unlockRequestSubmitted:
        return .none
      }
    }
  }

  struct RootReducer: RootReducing {
    @Dependency(\.filterXpc) var filterXpc
  }
}

extension BlockedRequestsFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Self.Action> {
    switch action {
    case .menuBar(.viewNetworkTrafficClicked):
      state.blockedRequests.windowOpen = true
      return .fireAndForget {
        // TODO: handle error
        _ = await filterXpc.setBlockStreaming(true)
      }

    case .xpc(.receivedExtensionMessage(.blockedRequest(let request))):
      state.blockedRequests.requests.append(request)
      return .none

    default:
      return .none
    }
  }
}

extension BlockedRequestsFeature {
  struct ViewState: Equatable, Encodable {
    var windowOpen = false
    var requests: [Request] = []
    var filterText = ""
    var tcpOnly = false
    var unlockRequest = RequestState<String>.idle

    init(state: BlockedRequestsFeature.State) {
      windowOpen = state.windowOpen
      requests = state.requests.map(\.view)
      filterText = state.filterText
      tcpOnly = state.tcpOnly
      unlockRequest = state.unlockRequest
    }
  }
}

extension BlockedRequestsFeature.ViewState {
  struct Request: Equatable, Encodable {
    var id: UUID
    var time: Date
    var target: String
    var `protocol`: IpProtocol.Kind
    var searchableText: String
    var app: String
  }
}

extension BlockedRequest {
  var view: BlockedRequestsFeature.ViewState.Request {
    .init(
      id: id,
      time: time,
      target: url ?? hostname ?? ipAddress ?? "unknown",
      protocol: ipProtocol?.kind ?? .other,
      searchableText: [url, hostname, ipAddress, app.searchableText]
        .compactMap { $0 }
        .joined(separator: " "),
      app: app.displayName ?? app.bundleId
    )
  }
}

extension AppDescriptor {
  var searchableText: String {
    ([displayName, bundleId, slug] + .init(categories))
      .compactMap { $0 }
      .joined(separator: " ")
  }
}

extension BlockedRequestsFeature.Reducer {
  typealias State = BlockedRequestsFeature.State
  typealias Action = BlockedRequestsFeature.Action

  // every time the user interacts with the blocked requests window, that
  // shows they are still actively interested in the blocked requests, so
  // we restart the 5-minute expiration timer
  func restartBlockStreaming() -> Effect<Action> {
    .fireAndForget { [setBlockStreaming = filterXpc.setBlockStreaming] in
      // probably ok to ignore error here, very unlikely to happen
      // we'll concentrate error handling for the initial window open event
      _ = await setBlockStreaming(true)
    }
  }

  func endBlockStreaming() -> Effect<Action> {
    .fireAndForget { [setBlockStreaming = filterXpc.setBlockStreaming] in
      // ok to ignore error here, worst that can happen is streaming expires on its own
      _ = await setBlockStreaming(false)
    }
  }
}
