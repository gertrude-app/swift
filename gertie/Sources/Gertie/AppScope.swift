public enum AppScope: Equatable, Hashable, Codable, Sendable {
  case unrestricted
  case webBrowsers
  case single(Single)

  public static var typescriptAlias: String {
    """
      | { type: 'unrestricted'  }
      | { type: 'webBrowsers'  }
      | { type: 'single'; single: SingleAppScope }
    """
  }
}

// extensions

public extension AppScope {
  enum Single: Equatable, Hashable, Codable, Sendable {
    case identifiedAppSlug(String)
    case bundleId(String)

    public static var typescriptAlias: String {
      """
        | { type: 'bundleId'; bundleId: string; }
        | { type: 'identifiedAppSlug'; identifiedAppSlug: string; }
      """
    }
  }

  func permits(_ app: AppDescriptor) -> Bool {
    switch self {
    case .unrestricted:
      return true
    case .webBrowsers:
      return app.categories.contains("browser")
    case .single(.identifiedAppSlug(let slug)):
      return app.slug == slug
    case .single(.bundleId(let bundleId)):
      return app.bundleId == bundleId
    }
  }
}

#if DEBUG
  public extension AppScope {
    static var mock: AppScope {
      .webBrowsers
    }

    static var empty: AppScope {
      .unrestricted
    }

    static var random: AppScope {
      switch Int.random(in: 1 ... 6) {
      case 1:
        return .webBrowsers
      case 2:
        return .unrestricted
      default:
        return .single(.random)
      }
    }
  }

  public extension AppScope.Single {
    static var mock: AppScope.Single {
      .bundleId("com.foo")
    }

    static var empty: AppScope.Single {
      .bundleId("")
    }

    static var random: AppScope.Single {
      if Bool.random() {
        return .bundleId("com.foo.\(Int.random(in: 10000 ... 99999))")
      } else {
        return .identifiedAppSlug("slug-\(Int.random(in: 10000 ... 99999))")
      }
    }
  }
#endif
