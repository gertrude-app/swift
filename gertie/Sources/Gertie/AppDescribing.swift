import Foundation

public protocol AppDescribing {
  var appIdManifest: AppIdManifest { get }
  func rootApp(fromAuditToken: Data?) -> (bundleId: String?, displayName: String?)
  func appCache(get: String) -> AppDescriptor?
  func appCache(insert: AppDescriptor, for: String) -> Void
}

public extension AppDescribing {
  func appDescriptor(for bundleId: String, auditToken: Data? = nil) -> AppDescriptor {
    if let cached = appCache(get: bundleId) {
      return cached
    }

    let slug = appIdManifest.appSlug(fromBundleId: bundleId)

    // if we can't find a slug for the bundle id, but we have a token, look for a root app
    if slug == nil, let token = auditToken {
      let (rootBundleId, rootDisplayName) = self.rootApp(fromAuditToken: token)
      if let rootBundleId = rootBundleId, rootBundleId != bundleId {
        var rootApp = self.appDescriptor(for: rootBundleId)

        // if we happened also to find a display name not known by the
        // AppIdManifest, override cache from the above call to self.appDescriptor()
        if rootApp.displayName == nil, let rootDisplayName {
          rootApp = AppDescriptor(
            bundleId: rootApp.bundleId,
            slug: rootApp.slug,
            displayName: rootDisplayName,
            categories: rootApp.categories
          )
          appCache(insert: rootApp, for: bundleId)
        }
        return rootApp
      }
    }

    let name = appIdManifest.displayName(fromBundleId: bundleId)
    let categories = Set(appIdManifest.categorySlugs(fromBundleId: bundleId))

    let descriptor = AppDescriptor(
      bundleId: bundleId,
      slug: slug,
      displayName: name,
      categories: categories
    )

    appCache(insert: descriptor, for: bundleId)
    return descriptor
  }

  func rootApp(fromAuditToken: Data?) -> (bundleId: String?, displayName: String?) {
    (nil, nil)
  }
}
