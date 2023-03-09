import Foundation
import SharedCore
import XCore

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
    "RequestsWindowState.Filter(\((try? JSON.encode(self)) ?? "")"
  }
}

extension RequestsWindowState.Filter: Equatable {
  static func == (lhs: RequestsWindowState.Filter, rhs: RequestsWindowState.Filter) -> Bool {
    (try? JSON.encode(lhs)) == (try? JSON.encode(rhs))
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
