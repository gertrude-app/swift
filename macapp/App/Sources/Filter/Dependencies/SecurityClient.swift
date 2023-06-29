import Dependencies
import Foundation
import XCore

public struct SecurityClient: Sendable {
  public typealias RootApp = (bundleId: String?, displayName: String?)
  public var userIdFromAuditToken: @Sendable (Data?) -> uid_t?
  public var rootAppFromAuditToken: @Sendable (Data?) -> RootApp

  public init(
    userIdFromAuditToken: @escaping @Sendable (Data?) -> uid_t?,
    rootAppFromAuditToken: @escaping @Sendable (Data?) -> RootApp
  ) {
    self.userIdFromAuditToken = userIdFromAuditToken
    self.rootAppFromAuditToken = rootAppFromAuditToken
  }
}

extension SecurityClient: DependencyKey {
  public static var liveValue = Self(
    userIdFromAuditToken: { auditToken in
      guard let auditToken, auditToken.count == MemoryLayout<audit_token_t>.size else {
        return nil
      }

      let token: audit_token_t? = auditToken.withUnsafeBytes { buffer in
        guard let baseAddress = buffer.baseAddress else { return nil }
        return baseAddress.assumingMemoryBound(to: audit_token_t.self).pointee
      }

      return token.map { audit_token_to_ruid($0) }
    },
    rootAppFromAuditToken: { token in
      var app: RootApp = (nil, nil)
      guard let token else { return app }

      var secCode: SecCode?
      let auditStatus = SecCodeCopyGuestWithAttributes(
        nil,
        [kSecGuestAttributeAudit: token] as NSDictionary,
        [],
        &secCode
      )

      guard auditStatus == errSecSuccess, let code = secCode else {
        return app
      }

      var secStaticCode: SecStaticCode?
      let codeStatus = SecCodeCopyStaticCode(code, [], &secStaticCode)
      guard codeStatus == errSecSuccess, let staticCode = secStaticCode else {
        return app
      }

      var secInfo: CFDictionary?
      let infoStatus = SecCodeCopySigningInformation(staticCode, [], &secInfo)

      guard infoStatus == errSecSuccess,
            let info = secInfo as? [String: Any],
            let main = info["main-executable"] as? NSURL,
            let urlString = main.absoluteString else {
        return app
      }

      let (rootAppUrl, displayName) = urlData(from: urlString)
      app.displayName = displayName

      guard rootAppUrl.contains("Applications/"), let url = NSURL(string: rootAppUrl) else {
        return app
      }

      // there are lots more good things in the bundle, try logging out the keys, etc.
      let bundle = CFBundleCopyInfoDictionaryForURL(url) as NSDictionary
      if app.displayName == nil, let bundleDisplayName = bundle["displayName"] as? String {
        app.displayName = bundleDisplayName
      }

      guard let rootBundleId = bundle["CFBundleIdentifier"] as? String else {
        return app
      }

      app.bundleId = rootBundleId
      return app
    }
  )
}

extension SecurityClient: TestDependencyKey {
  public static let testValue = Self(
    userIdFromAuditToken: { _ in nil },
    rootAppFromAuditToken: { _ in (nil, nil) }
  )
}

public extension DependencyValues {
  var security: SecurityClient {
    get { self[SecurityClient.self] }
    set { self[SecurityClient.self] = newValue }
  }
}

// helpers

private func urlData(from urlString: String) -> (rootAppUrl: String, displayName: String?) {
  var displayName: String?
  var rootAppUrl = urlString
  let urlParts = urlString.components(separatedBy: ".app")

  if urlParts.count > 1, let first = urlParts.first {
    rootAppUrl = first + ".app"

    if let basename = rootAppUrl.components(separatedBy: "/").last {
      displayName =
        basename
          .removeSuffix(".app")
          .regexReplace("%20", " ")
          .regexRemove(#" ?\d+$"#)
    }
  }

  return (rootAppUrl, displayName)
}

private extension String {
  func removeSuffix(_ suffix: String) -> String {
    if !hasSuffix(suffix) {
      return self
    }
    return String(prefix(count - suffix.count))
  }
}
