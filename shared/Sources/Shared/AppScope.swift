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
