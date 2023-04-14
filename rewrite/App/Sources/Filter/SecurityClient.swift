import Dependencies
import Foundation

public struct SecurityClient: Sendable {
  public var userIdFromAuditToken: @Sendable (Data?) -> uid_t?
  public init(userIdFromAuditToken: @escaping @Sendable (Data?) -> uid_t?) {
    self.userIdFromAuditToken = userIdFromAuditToken
  }
}

extension SecurityClient: DependencyKey {
  public static var liveValue = Self(
    userIdFromAuditToken: { auditToken in
      guard let auditToken else {
        return nil
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

      return audit_token_to_ruid(token)
    }
  )
}

extension SecurityClient: TestDependencyKey {
  public static let testValue = Self(
    userIdFromAuditToken: { _ in nil }
  )
}

public extension DependencyValues {
  var security: SecurityClient {
    get { self[SecurityClient.self] }
    set { self[SecurityClient.self] = newValue }
  }
}
