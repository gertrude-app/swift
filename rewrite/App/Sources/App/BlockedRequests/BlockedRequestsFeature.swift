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
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .openWindow:
        state.windowOpen = true
        return .none
      case .closeWindow:
        state.windowOpen = false
        return .none
      case .filterTextUpdated(let text):
        state.filterText = text
        return .none
      case .tcpOnlyToggled:
        state.tcpOnly.toggle()
        return .none
      case .clearRequestsClicked:
        state.requests = []
        return .none
      case .unlockRequestSubmitted:
        return .none
      }
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
}
