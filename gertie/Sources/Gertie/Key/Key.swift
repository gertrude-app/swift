public enum Key: Hashable, Codable, Sendable {
  case domain(domain: Domain, scope: AppScope)
  case anySubdomain(domain: Domain, scope: AppScope)
  case skeleton(scope: AppScope.Single)
  case domainRegex(pattern: DomainRegexPattern, scope: AppScope)
  case path(path: Path, scope: AppScope)
  case ipAddress(ipAddress: Ip, scope: AppScope)
}

public extension Key {
  static var typescriptAlias: String {
    """
      | { type: 'anySubdomain'; domain: string; scope: AppScope }
      | { type: 'domain'; domain: string; scope: AppScope }
      | { type: 'domainRegex'; pattern: string; scope: AppScope }
      | { type: 'skeleton'; scope: SingleAppScope }
      | { type: 'ipAddress'; ipAddress: string; scope: AppScope }
      | { type: 'path'; path: string; scope: AppScope }
    """
  }
}

public extension Key {
  struct Domain: Equatable, Hashable, Codable, Sendable {
    public let string: String
  }

  struct DomainRegexPattern: Hashable, Codable, Sendable {
    public let string: String
    public let regex: String
  }

  struct Path: Hashable, Codable, Sendable {
    public let domain: Domain
    public let path: String
    public let regex: String?
  }

  struct Ip: Hashable, Codable, Sendable {
    public let string: String
  }
}

#if DEBUG
  extension Key.Domain: Mocked {
    public static var mock: Key.Domain { .init(string: "example.com") }
    public static var empty: Key.Domain { .init(string: "") }
  }

  extension Key: RandomMocked {
    public static let mock = Self.domain(domain: .mock, scope: .mock)
    public static let empty = Self.domain(domain: .empty, scope: .empty)

    public static var random: Key {
      switch Int.random(in: 1 ... 6) {
      case 1:
        return .domain(domain: .init("foo.com")!, scope: .random)
      case 2:
        return .anySubdomain(domain: .init("foo.com")!, scope: .random)
      case 3:
        return .skeleton(scope: .random)
      case 4:
        return .domainRegex(pattern: .init("foo-*.com")!, scope: .random)
      case 5:
        return .path(path: .init("foo.com/bar")!, scope: .random)
      default:
        return .ipAddress(ipAddress: .init("1.2.3.4")!, scope: .random)
      }
    }
  }
#endif
