public enum NetworkDecisionVerdict: String, Codable, Equatable, CaseIterable, Sendable {
  case block
  case allow
}

public enum NetworkDecisionReason: String, Codable, Equatable, CaseIterable, Sendable {
  case systemUser
  case userIsExempt
  case missingKeychains
  case missingUserId
  case defaultNotAllowed
  case ipAllowed
  case domainAllowed
  case pathAllowed
  case fileExtensionAllowed
  case appBlocked
  case fromGertrudeApp
  case appUnrestricted
  case dns
  case nonDnsUdp
  case systemUiServerInternal
  case filterSuspended
}

// extensions

extension NetworkDecisionReason: CustomStringConvertible {
  public var description: String {
    switch self {
    case .defaultNotAllowed:
      return "no keychain allowed it"
    case .missingUserId:
      return "a mac user id for the request could not be determined"
    case .missingKeychains:
      return "no keys for the mac user were found"
    case .ipAllowed:
      return "a keychain allowed the IP address"
    case .domainAllowed:
      return "a keychain allowed the domain"
    case .pathAllowed:
      return "a keychain allowed the path"
    case .fileExtensionAllowed:
      return "a keychain allowed the file extension"
    case .appBlocked:
      return "the user blocked the app from any network access"
    case .appUnrestricted:
      return "a keychain granted the app unrestricted network access"
    case .fromGertrudeApp:
      return "the request came from the Gertie app"
    case .dns:
      return "all DNS requests are allowed"
    case .nonDnsUdp:
      return "all UDP requests (except DNS) are blocked"
    case .systemUser:
      return "the request came from an internal operating system user"
    case .userIsExempt:
      return "the request came from a user designated as exempt from blocking"
    case .filterSuspended:
      return "the filter was suspended at the time of the request"
    case .systemUiServerInternal:
      return
        "the request was made by an internal system networking utility related to the menu bar"
    }
  }
}
