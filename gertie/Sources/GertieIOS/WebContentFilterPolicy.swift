#if os(iOS)
  import ManagedSettings
#endif

public enum WebContentFilterPolicy: Codable, Equatable, Sendable {
  case allowAll
  case blockAdult
  case blockAdultAnd(Set<String>)
  case blockAllExcept(Set<String>)
  case blockAll
}

#if os(iOS)
  public extension WebContentFilterPolicy {
    var managedSettingsPolicy: ManagedSettings.WebContentSettings.FilterPolicy {
      switch self {
      case .allowAll:
        .none
      case .blockAll:
        .all(except: [])
      case .blockAdult:
        .auto()
      case .blockAdultAnd(let domains):
        .auto(Set(domains.map { WebDomain(domain: $0) }), except: [])
      case .blockAllExcept(let except):
        .all(except: Set(except.map { WebDomain(domain: $0) }))
      }
    }
  }

  public extension Set<WebDomain> {
    var domainStrings: [String] {
      var domains: [String] = []
      for item in self {
        if let domain = item.domain {
          domains.append(domain)
        }
      }
      return domains
    }
  }

  public extension ManagedSettings.WebContentSettings.FilterPolicy {
    var gertiePolicy: WebContentFilterPolicy {
      switch self {
      case .none:
        return .allowAll
      case .all(let except):
        return except.isEmpty ? .blockAll : .blockAllExcept(Set(except.domainStrings))
      case .auto(let domains, _):
        return domains.isEmpty ? .blockAdult : .blockAdultAnd(Set(domains.domainStrings))
      case .specific:
        // not semantically correct, but we don't support this option, unreachable
        return .blockAll
      @unknown default:
        return .blockAll
      }
    }
  }
#endif

public extension WebContentFilterPolicy {
  enum Kind: String, Codable, Equatable, Sendable {
    case allowAll
    case blockAdult
    case blockAdultAnd
    case blockAllExcept
    case blockAll

    public init?(string: String) {
      switch string {
      case "allowAll": self = .allowAll
      case "blockAdult": self = .blockAdult
      case "blockAdultAnd": self = .blockAdultAnd
      case "blockAllExcept": self = .blockAllExcept
      case "blockAll": self = .blockAll
      default: return nil
      }
    }
  }

  var shortDesc: String {
    switch self {
    case .allowAll:
      "allowAll"
    case .blockAdult:
      "blockAdult"
    case .blockAdultAnd(let domains):
      "blockAdultAnd(<\(domains.count) domains>)"
    case .blockAllExcept(let except):
      "blockAllExcept(<\(except.count) domains>)"
    case .blockAll:
      "blockAll"
    }
  }

  var kind: Kind {
    switch self {
    case .allowAll: .allowAll
    case .blockAdult: .blockAdult
    case .blockAdultAnd: .blockAdultAnd
    case .blockAllExcept: .blockAllExcept
    case .blockAll: .blockAll
    }
  }
}
