import Core
import Foundation
import os.log

public extension NetworkFilter {
  func earlyUserDecision(auditToken: Data?) -> FilterDecision.FromUserId {
    guard let userId = security.userIdFromAuditToken(auditToken) else {
      return logged(.block(.missingUserId))
    }

    // TODO: this should really be < 501, but would want to test first
    // as the 1.x.x version of the app has been using < 500 for a while
    if userId < 500 { // system user
      return logged(.allow(.systemUser(userId)))
    }

    if state.exemptUsers.contains(userId) {
      return logged(.allow(.exemptUser(userId)))
    }

    if let suspension = state.suspensions[userId],
       suspension.isActive,
       suspension.scope == .unrestricted {
      return logged(.allow(.filterSuspended(userId)))
    }

    return .none(userId)
  }

  private func logged(_ decision: FilterDecision.FromUserId) -> FilterDecision.FromUserId {
    #if DEBUG
      if getuid() < 500 { // prevent logging when running tests
        switch decision {
        case .block(let reason):
          os_log("[G•] filter early decision: BLOCK, reason: %{public}@", "\(reason)")
        case .allow(let reason):
          os_log("[G•] filter early decision: ALLOW, reason: %{public}@", "\(reason)")
        case .none:
          break
        }
      }
    #endif
    return decision
  }
}
