public struct AppIdManifest: Codable, Equatable, Sendable {
  public typealias IdentifiedAppSlug = String
  public typealias AppBundleId = String
  public typealias AppDisplayName = String
  public typealias AppCategorySlug = String

  public var apps: [IdentifiedAppSlug: Set<AppBundleId>] = [:]
  public var displayNames: [IdentifiedAppSlug: AppDisplayName] = [:]
  public var categories: [AppCategorySlug: Set<IdentifiedAppSlug>] = [:]

  public var isEmpty: Bool {
    self.categories.isEmpty && self.apps.isEmpty && self.displayNames.isEmpty
  }

  public init(
    apps: [String: Set<String>] = [:],
    displayNames: [String: String] = [:],
    categories: [String: Set<String>] = [:],
  ) {
    self.apps = apps
    self.displayNames = displayNames
    self.categories = categories
  }

  public func appSlug(fromBundleId bundleId: String?) -> String? {
    guard let bundleId else {
      return nil
    }

    for (appSlug, bundleIds) in self.apps {
      if bundleIds.contains(bundleId) {
        return appSlug
      }
    }

    return nil
  }

  public func displayName(fromBundleId bundleId: String?) -> String? {
    self.displayName(fromAppSlug: self.appSlug(fromBundleId: bundleId))
  }

  public func displayName(fromAppSlug appSlug: String?) -> String? {
    guard let appSlug else {
      return nil
    }
    return self.displayNames[appSlug]
  }

  public func categorySlugs(fromBundleId bundleId: String?) -> [String] {
    self.categorySlugs(fromAppSlug: self.appSlug(fromBundleId: bundleId))
  }

  public func categorySlugs(fromAppSlug appSlug: String?) -> [String] {
    guard let appSlug else {
      return []
    }

    var slugs: [String] = []
    for (categorySlug, apps) in self.categories {
      if apps.contains(appSlug) {
        slugs.append(categorySlug)
      }
    }
    return slugs
  }
}

#if DEBUG
  extension AppIdManifest: Mocked {
    public static var mock: AppIdManifest {
      .init(
        apps: ["xcode": ["com.apple.xcode"]],
        displayNames: ["come.apple.xcode": "Xcode"],
        categories: ["coding": ["xcode"]],
      )
    }

    public static var empty: AppIdManifest {
      .init()
    }
  }
#endif
