import XCore

public extension Key.Domain {
  init?(_ input: String) {
    var domain = input
    if domain.starts(with: "http") {
      domain = domain.regexRemove("^https?://")
    }
    if domain.last == "/" {
      domain.removeLast()
    }
    guard !domain.contains("/"), URL(string: domain) != nil else {
      return nil
    }
    string = domain.lowercased()
  }

  func matches(hostname: String) -> Bool {
    let hostname = hostname.lowercased()
    if hostname == string {
      return true
    }

    if hostname.starts(with: "www."), hostname == "www.\(string)" {
      return true
    }

    if string.starts(with: "www."), "www.\(hostname)" == string {
      return true
    }

    return false
  }

  func matchesAnySubdomain(of hostname: String) -> Bool {
    matches(hostname: hostname) || hostname.lowercased().hasSuffix(".\(string)")
  }
}

public extension Key.DomainRegexPattern {
  init?(_ input: String) {
    guard input.contains("*"),
          Key.Domain(input.replacingOccurrences(of: "*", with: "a")) != nil else {
      return nil
    }

    string = input.lowercased()
    regex = string
      .replacingOccurrences(of: ".", with: "\\.")
      .replacingOccurrences(of: "*", with: ".*")
  }
}

public extension Key.Path {
  init?(_ input: String) {
    let parts = input.split(separator: "/", maxSplits: 1)
    guard parts.count == 2, !parts[1].isEmpty,
          let domain = Key.Domain(String(parts[0])) else {
      return nil
    }
    self.domain = domain
    path = String(parts[1]).lowercased()
    if path.contains("*") {
      regex = "^" + domain.string + "/" + path
        .replacingOccurrences(of: ".", with: "\\.")
        .replacingOccurrences(of: "*", with: ".*") + "$"
    } else {
      regex = nil
    }
  }

  func matches(url: String) -> Bool {
    let url = url.regexRemove("^https?://").lowercased()
    if let regex = regex {
      return url.matchesRegex(regex)
    } else {
      return url.regexRemove("/$") == domain.string + "/" + path.regexRemove("/$")
    }
  }
}

public extension Key.Ip {
  init?(_ input: String) {
    // these regexes are naive, but probably good enough
    if input.matchesRegex(#"^\d+\.\d+\.\d+\.\d+"#) {
      string = input
    } else if input.matchesRegex(#"^[0-9a-zA-Z]+:[0-9a-zA-Z:%]+$"#) {
      string = input
    } else {
      return nil
    }
  }
}

public extension AppScope {
  static var safeFallback: AppScope {
    .single(.bundleId(UUID().uuidString))
  }
}

// expressible by string literal (test only)

#if DEBUG
  extension Key.Path: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
      self = Key.Path(value)!
    }
  }

  extension Key.Ip: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
      self = Key.Ip(value)!
    }
  }

  extension Key.DomainRegexPattern: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
      self = Key.DomainRegexPattern(value)!
    }
  }

  extension Key.Domain: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
      self = Key.Domain(value)!
    }
  }
#endif
