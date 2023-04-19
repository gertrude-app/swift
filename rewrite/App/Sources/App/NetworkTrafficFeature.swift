import ComposableArchitecture
import Foundation
import Shared

struct NetworkTrafficFeature: Reducer {
  struct State: Equatable {
    var requests: [Request] = []
    var filterText = ""
    var tcpOnly = true
  }

  enum Action: Equatable, Sendable {
    case updateFilterText(String)
    case toggleTcpOnly
    case clearRequests
  }

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    .none
  }
}

extension NetworkTrafficFeature.State {
  struct Request: Equatable {
    var id: UUID
    var selected: Bool
    var `protocol`: IpProtocol
    var time: Date
    var searchableText: String
    var app: String
  }
}
