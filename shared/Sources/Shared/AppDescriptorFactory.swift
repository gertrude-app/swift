import Foundation

public final class AppDescriptorFactory {
  private let manifest: AppIdManifest
  private let rootAppQuery: RootAppQuery?
  private var cache: [String: AppDescriptor] = [:]

  public init(appIdManifest: AppIdManifest = .init(), rootAppQuery: RootAppQuery? = nil) {
    manifest = appIdManifest
    self.rootAppQuery = rootAppQuery
  }

  public func make(bundleId: String, auditToken: Data? = nil) -> AppDescriptor {
    if let cached = cache[bundleId] {
      return cached
    }

    let slug = manifest.appSlug(fromBundleId: bundleId)

    // if we can't find a slug for the bundle id, but we've been given
    // an RootAppQuery and an audit token, try to determine the root app
    if slug == nil, let query = rootAppQuery, let token = auditToken {
      let (rootBundleId, rootDisplayName) = query.get(from: token)
      if let rootBundleId = rootBundleId, rootBundleId != bundleId {
        var rootApp = make(bundleId: rootBundleId)

        // if we happened also to find a display name not known by the
        // AppIdManifest, override cache from the above call to self.make()
        if rootApp.displayName == nil, let rootDisplayName = rootDisplayName {
          rootApp = AppDescriptor(
            bundleId: rootApp.bundleId,
            slug: rootApp.slug,
            displayName: rootDisplayName,
            categories: rootApp.categories
          )
          cache[bundleId] = rootApp
        }
        return rootApp
      }
    }

    let name = manifest.displayName(fromBundleId: bundleId)
    let categories = Set(manifest.categorySlugs(fromBundleId: bundleId))

    let descriptor = AppDescriptor(
      bundleId: bundleId,
      slug: slug,
      displayName: name,
      categories: categories
    )

    cache[bundleId] = descriptor

    return descriptor
  }
}
