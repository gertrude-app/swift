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
      true
    case .webBrowsers:
      app.categories.contains("browser")
    case .single(.identifiedAppSlug(let slug)):
      app.slug == slug
    case .single(.bundleId(let bundleId)):
      app.bundleId == bundleId
    }
  }
}

#if DEBUG
  extension AppScope: RandomMocked {
    public static var mock: AppScope {
      .webBrowsers
    }

    public static var empty: AppScope {
      .unrestricted
    }

    public static var random: AppScope {
      switch Int.random(in: 1 ... 6) {
      case 1:
        .webBrowsers
      case 2:
        .unrestricted
      default:
        .single(.random)
      }
    }
  }

  extension AppScope.Single: RandomMocked {
    public static var mock: AppScope.Single {
      .bundleId("com.foo")
    }

    public static var empty: AppScope.Single {
      .bundleId("")
    }

    public static var random: AppScope.Single {
      if Bool.random() {
        .bundleId("com.foo.\(Int.random(in: 10000 ... 99999))")
      } else {
        .identifiedAppSlug("slug-\(Int.random(in: 10000 ... 99999))")
      }
    }
  }
#endif
