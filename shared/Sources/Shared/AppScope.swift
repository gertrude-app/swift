public enum AppScope: Equatable, Hashable, Codable {
  case unrestricted
  case webBrowsers
  case single(Single)

  public static var customTs: String? {
    """
    export type __self__ =
      | { type: 'unrestricted'  }
      | { type: 'webBrowsers'  }
      | { type: 'single'; single: SingleAppScope }
    """
  }
}

// extensions

public extension AppScope {
  enum Single: Equatable, Hashable, Codable {
    case identifiedAppSlug(String)
    case bundleId(String)

    public static var customTs: String? {
      """
      export type __self__ =
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
