public enum Key: Hashable, Codable {
  case domain(domain: Domain, scope: AppScope)
  case anySubdomain(domain: Domain, scope: AppScope)
  case skeleton(scope: AppScope.Single)
  case domainRegex(pattern: DomainRegexPattern, scope: AppScope)
  case path(path: Path, scope: AppScope)
  case ipAddress(ipAddress: Ip, scope: AppScope)

  public static var customTs: String? {
    """
    export type __self__ =
      | { type: 'anySubdomain'; domain: string; scope: AppScope }
      | { type: 'domain'; domain: string; scope: AppScope }
      | { type: 'domainRegex'; pattern: string; scope: AppScope }
      | { type: 'skeleton'; pattern: string; scope: SingleAppScope }
      | { type: 'ipAddress'; ipAddress: string; scope: AppScope }
      | { type: 'path'; path: string; scope: AppScope };
    """
  }
}

public extension Key {
  struct Domain: Equatable, Hashable, Codable {
    public let string: String
  }

  struct DomainRegexPattern: Hashable, Codable {
    public let string: String
    public let regex: String
  }

  struct Path: Hashable, Codable {
    public let domain: Domain
    public let path: String
    public let regex: String?
  }

  struct Ip: Hashable, Codable {
    public let string: String
  }
}
