import Foundation

protocol SourceAppAuditor {
  func userId(fromAuditToken auditToken: Data?) -> uid_t?
}

class CachingSourceAppAuditor: SourceAppAuditor {
  private var userIdMap: [Data: uid_t] = [:]

  func userId(fromAuditToken auditToken: Data?) -> uid_t? {
    guard let auditToken = auditToken else {
      return nil
    }

    if let cached = userIdMap[auditToken] {
      return cached
    }

    guard auditToken.count == MemoryLayout<audit_token_t>.size else {
      return nil
    }

    let tokenT: audit_token_t? = auditToken.withUnsafeBytes { buf in
      guard let baseAddress = buf.baseAddress else {
        return nil
      }
      return baseAddress.assumingMemoryBound(to: audit_token_t.self).pointee
    }

    guard let token = tokenT else {
      return nil
    }

    let userId = audit_token_to_ruid(token)
    userIdMap[auditToken] = userId
    return userId
  }
}
