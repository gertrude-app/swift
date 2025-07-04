import ManagedSettings

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
