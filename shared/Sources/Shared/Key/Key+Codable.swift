import Foundation

public extension Key {
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .domain(domain: let domain, scope: let scope):
      try container.encode("domain", forKey: .type)
      try container.encode(domain.string, forKey: .domain)
      try container.encode(scope, forKey: .scope)
    case .anySubdomain(let domain, scope: let scope):
      try container.encode("anySubdomain", forKey: .type)
      try container.encode(domain.string, forKey: .domain)
      try container.encode(scope, forKey: .scope)
    case .skeleton(let scope):
      try container.encode("skeleton", forKey: .type)
      try container.encode(scope, forKey: .scope)
    case .domainRegex(let pattern, let scope):
      try container.encode("domainRegex", forKey: .type)
      try container.encode(pattern.string, forKey: .pattern)
      try container.encode(scope, forKey: .scope)
    case .path(let path, let scope):
      try container.encode("path", forKey: .type)
      try container.encode("\(path.domain.string)/\(path.path)", forKey: .path)
      try container.encode(scope, forKey: .scope)
    case .ipAddress(let ip, let scope):
      try container.encode("ipAddress", forKey: .type)
      try container.encode(ip.string, forKey: .ipAddress)
      try container.encode(scope, forKey: .scope)
    }
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let type = try values.decode(String.self, forKey: .type)
    switch type {
    case "domain", "anySubdomain":
      let scope = try values.decode(AppScope.self, forKey: .scope)
      let domainString = try values.decode(String.self, forKey: .domain)
      guard let domain = Key.Domain(domainString) else {
        throw ModelDecodingError("invalid domain string \(domainString) for Key")
      }
      self = type == "domain" ? .domain(domain: domain, scope: scope) :
        .anySubdomain(domain: domain, scope: scope)
    case "skeleton":
      let scope = try values.decode(AppScope.Single.self, forKey: .scope)
      self = .skeleton(scope: scope)
    case "domainRegex":
      let scope = try values.decode(AppScope.self, forKey: .scope)
      let patternString = try values.decode(String.self, forKey: .pattern)
      guard let pattern = Key.DomainRegexPattern(patternString) else {
        throw ModelDecodingError("invalid domain regex pattern string \(patternString) for Key")
      }
      self = .domainRegex(pattern: pattern, scope: scope)
    case "path":
      let scope = try values.decode(AppScope.self, forKey: .scope)
      let pathString = try values.decode(String.self, forKey: .path)
      guard let path = Key.Path(pathString) else {
        throw ModelDecodingError("invalid path string \(pathString) for Key")
      }
      self = .path(path: path, scope: scope)
    case "ipAddress":
      let scope = try values.decode(AppScope.self, forKey: .scope)
      let ipString = try values.decode(String.self, forKey: .ipAddress)
      guard let ip = Key.Ip(ipString) else {
        throw ModelDecodingError("invalid ip string \(ipString) for Key")
      }
      self = .ipAddress(ip: ip, scope: scope)

    default:
      throw ModelDecodingError("unknown key type `\(type)`")
    }
  }

  enum CodingKeys: String, CodingKey {
    case type, domain, scope, pattern, path, ipAddress
  }
}

public extension AppScope {
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .unrestricted:
      try container.encode("unrestricted", forKey: .type)
    case .webBrowsers:
      try container.encode("webBrowsers", forKey: .type)
    case .single(let single):
      try container.encode("single", forKey: .type)
      try container.encode(single, forKey: .single)
    }
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let type = try values.decode(String.self, forKey: .type)
    switch type {
    case "unrestricted":
      self = .unrestricted
    case "webBrowsers":
      self = .webBrowsers
    case "single":
      let single = try values.decode(AppScope.Single.self, forKey: .single)
      self = .single(single)
    default:
      throw ModelDecodingError("unknown AppScope type: \(type)")
    }
  }

  enum CodingKeys: String, CodingKey {
    case type, single
  }
}

public extension AppScope.Single {

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .identifiedAppSlug(let slug):
      try container.encode("identifiedAppSlug", forKey: .type)
      try container.encode(slug, forKey: .identifiedAppSlug)
    case .bundleId(let bundleId):
      try container.encode("bundleId", forKey: .type)
      try container.encode(bundleId, forKey: .bundleId)
    }
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let type = try values.decode(String.self, forKey: .type)
    switch type {
    case "identifiedAppSlug":
      if let slug = try? values.decode(String.self, forKey: .identifiedAppSlug) {
        self = .identifiedAppSlug(slug)
      } else {
        throw ModelDecodingError("missing expected AppScope.Single .identifiedAppSlug")
      }
    case "bundleId":
      if let bundleId = try? values.decode(String.self, forKey: .bundleId) {
        self = .bundleId(bundleId)
      } else {
        throw ModelDecodingError("missing expected AppScope.Single .bundleId value")
      }
    default:
      throw ModelDecodingError("unexpected ApScope.Single.type")
    }
  }

  enum CodingKeys: String, CodingKey {
    case type, bundleId, identifiedAppSlug
  }
}

public struct ModelDecodingError: Error, LocalizedError, CustomStringConvertible,
  CustomDebugStringConvertible {
  public let message: String

  public init(_ message: String) {
    self.message = message
  }

  public var errorDescription: String? {
    description
  }

  public var description: String {
    "ModelDecodingError (Invalid JSON): \(message)"
  }

  public var debugDescription: String {
    "ModelDecodingError(message: \"\(message)\")"
  }
}
