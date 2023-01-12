import Foundation
import SharedCore

class RequestsWindowState {
  class Filter: Codable {
    var showBlockedRequestsOnly = true
    var showTcpRequestsOnly = true
    var byText = false
    var text = ""
    init() {}
  }

  var requests = [FilterDecision]()
  var selectedRequests = Set<UUID>()
  var filter = Filter()

  var unlockRequestText = ""
  var unlockRequestFetchState = FetchState<Void>.waiting
  init() {}
}

// protocol conformance

extension RequestsWindowState.Filter: CustomStringConvertible {
  var description: String {
    "RequestsWindowState.Filter(\(json ?? "")"
  }
}

extension RequestsWindowState.Filter: Equatable {
  static func == (lhs: RequestsWindowState.Filter, rhs: RequestsWindowState.Filter) -> Bool {
    lhs.json == rhs.json
  }
}

extension RequestsWindowState: Equatable {
  static func == (lhs: RequestsWindowState, rhs: RequestsWindowState) -> Bool {
    if lhs.filter != rhs.filter {
      return false
    }
    if lhs.requests != rhs.requests {
      return false
    }
    if lhs.selectedRequests != rhs.selectedRequests {
      return false
    }
    if lhs.unlockRequestText != rhs.unlockRequestText {
      return false
    }
    if lhs.unlockRequestFetchState != rhs.unlockRequestFetchState {
      return false
    }
    return true
  }
}
