import Foundation
import os.log

public enum EarlyDecision: Equatable {
  public enum Reason: Equatable {
    case missingUserId
    case systemUser(uid_t)
    case exemptUser(uid_t)
    case suspended(uid_t)
    #if DEBUG
      case dev
    #endif
  }

  case block(Reason)
  case allow(Reason)
  case none(uid_t)
}

public extension NetworkFilter {
  func earlyUserDecision(auditToken: Data?) -> EarlyDecision {
    guard let userId = security.userIdFromAuditToken(auditToken) else {
      return logged(.block(.missingUserId))
    }

    // TODO: this should really be < 501, but would want to test first
    if userId < 500 { // system user
      return logged(.allow(.systemUser(userId)))
    }

    if state.exemptUsers.contains(userId) {
      return logged(.allow(.exemptUser(userId)))
    }

    if let suspension = state.suspensions[userId],
       suspension.isActive,
       suspension.scope == .unrestricted {
      return logged(.allow(.suspended(userId)))
    }

    return .none(userId)
  }

  private func logged(_ decision: EarlyDecision) -> EarlyDecision {
    #if DEBUG
      if getuid() < 500 { // only log/modify decisions for root
        switch decision {
        case .block(let reason):
          os_log("[G•] filter early decision: BLOCK, reason: %{public}@", "\(reason)")
          return .allow(.dev)
        case .allow(let reason):
          os_log("[G•] filter early decision: ALLOW, reason: %{public}@", "\(reason)")
        case .none:
          break
        }
      }
      return decision
    #else
      return decision
    #endif
  }
}
