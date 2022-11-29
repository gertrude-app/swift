public enum AppScope: Equatable, Hashable, Codable {
  case unrestricted
  case webBrowsers
  case single(Single)
}

// extensions

public extension AppScope {
  enum Single: Equatable, Hashable, Codable {
    case identifiedAppSlug(String)
    case bundleId(String)
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
