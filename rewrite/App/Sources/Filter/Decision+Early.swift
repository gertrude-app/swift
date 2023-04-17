import Foundation

public enum EarlyDecision: Equatable {
  case block
  case allow
  case none(uid_t)
}

public extension NetworkFilter {
  func earlyUserDecision(auditToken: Data?) -> EarlyDecision {
    guard let userId = security.userIdFromAuditToken(auditToken) else {
      return .block
    }

    // TODO: this should really be < 501, but would want to test first
    if userId < 500 { // system user
      return .allow
    }

    if state.exemptUsers.contains(userId) {
      return .allow
    }

    if let suspension = state.suspensions[userId],
       suspension.isActive,
       suspension.scope == .unrestricted {
      return .allow
    }

    return .none(userId)
  }
}
