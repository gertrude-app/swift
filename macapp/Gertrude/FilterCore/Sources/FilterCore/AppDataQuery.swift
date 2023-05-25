import Foundation
import Gertie

public struct RootAppDataQuery: RootAppQuery {

  public init() {}

  public func get(from token: Data?) -> RootApp {
    var data: RootApp = (nil, nil)
    guard let token = token else {
      return data
    }

    var secCode: SecCode?
    let auditStatus = SecCodeCopyGuestWithAttributes(
      nil,
      [kSecGuestAttributeAudit: token] as NSDictionary,
      [],
      &secCode
    )

    guard auditStatus == errSecSuccess, let code = secCode else {
      return data
    }

    var secStaticCode: SecStaticCode?
    let codeStatus = SecCodeCopyStaticCode(code, [], &secStaticCode)
    guard codeStatus == errSecSuccess, let staticCode = secStaticCode else {
      return data
    }

    var secInfo: CFDictionary?
    let infoStatus = SecCodeCopySigningInformation(staticCode, [], &secInfo)
    guard infoStatus == errSecSuccess, let info = secInfo as? [String: Any] else {
      return data
    }

    guard let main = info["main-executable"] as? NSURL, let urlString = main.absoluteString else {
      return data
    }

    let (rootAppUrl, displayName) = Self.urlData(from: urlString)
    data.displayName = displayName

    guard rootAppUrl.contains("Applications/") else {
      return data
    }

    guard let url = NSURL(string: rootAppUrl) else {
      return data
    }

    // there are lots more good things in the bundle, try logging out the keys, etc.
    let bundle = CFBundleCopyInfoDictionaryForURL(url) as NSDictionary

    if data.displayName == nil, let bundleDisplayName = bundle["displayName"] as? String {
      data.displayName = bundleDisplayName
    }

    guard let rootBundleId = bundle["CFBundleIdentifier"] as? String else {
      return data
    }

    data.bundleId = rootBundleId
    return data
  }

  static func urlData(from urlString: String) -> (rootAppUrl: String, displayName: String?) {
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
}
