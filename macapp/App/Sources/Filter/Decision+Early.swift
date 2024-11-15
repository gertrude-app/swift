import Core
import Foundation
import os.log

public extension NetworkFilter {
  func earlyUserDecision(auditToken: Data?) -> FilterDecision.FromUserId {
    guard let userId = self.security.userIdFromAuditToken(auditToken) else {
      return self.logDecision(.block(.missingUserId))
    }

    if userId == 500 {
      self.log(event: .init(id: "46b9ae45", detail: "filter user id=500"))
    }

    // TODO: this should really be < 501, but would want to test first
    // as the 1.x.x version of the app has been using < 500 for a while
    // @see https://github.com/gertrude-app/project/issues/152
    if userId < 500 { // system user
      return self.logDecision(.allow(.systemUser(userId)))
    }

    if let userDowntime = self.state.userDowntime[userId],
       userDowntime.shouldBlock(at: self.now, in: self.calendar) {
      return self.logDecision(.blockDuringDowntime(userId))
    }

    if self.state.exemptUsers.contains(userId) {
      return self.logDecision(.allow(.exemptUser(userId)))
    }

    if let suspension = self.state.suspensions[userId],
       suspension.isActive,
       suspension.scope == .unrestricted {
      return self.logDecision(.allow(.filterSuspended(userId)))
    }

    return .none(userId)
  }

  private func logDecision(_ decision: FilterDecision.FromUserId) -> FilterDecision.FromUserId {
    #if DEBUG
      if getuid() < 500 { // prevent logging when running tests
        switch decision {
        case .block(let reason):
          os_log("[D•] FILTER early decision: BLOCK, reason: %{public}@", "\(reason)")
        case .allow(let reason):
          os_log("[D•] FILTER early decision: ALLOW, reason: %{public}@", "\(reason)")
        case .blockDuringDowntime:
          os_log("[D•] FILTER early decision: DOWNTIME, block unless Gertrude")
        case .none:
          break
        }
      }
    #endif
    return decision
  }
}
