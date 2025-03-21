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
      "no keychain allowed it"
    case .missingUserId:
      "a mac user id for the request could not be determined"
    case .missingKeychains:
      "no keys for the mac user were found"
    case .ipAllowed:
      "a keychain allowed the IP address"
    case .domainAllowed:
      "a keychain allowed the domain"
    case .pathAllowed:
      "a keychain allowed the path"
    case .fileExtensionAllowed:
      "a keychain allowed the file extension"
    case .appBlocked:
      "the user blocked the app from any network access"
    case .appUnrestricted:
      "a keychain granted the app unrestricted network access"
    case .fromGertrudeApp:
      "the request came from the Gertie app"
    case .dns:
      "all DNS requests are allowed"
    case .nonDnsUdp:
      "all UDP requests (except DNS) are blocked"
    case .systemUser:
      "the request came from an internal operating system user"
    case .userIsExempt:
      "the request came from a user designated as exempt from blocking"
    case .filterSuspended:
      "the filter was suspended at the time of the request"
    case .systemUiServerInternal:
      "the request was made by an internal system networking utility related to the menu bar"
    }
  }
}
