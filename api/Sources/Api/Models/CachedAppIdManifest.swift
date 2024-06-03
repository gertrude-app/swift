import Gertie

// public interface

func getCachedAppIdManifest() async throws -> AppIdManifest {
  if let manifest = await cachedAppIdManifest.get() {
    return manifest
  }

  let manifest = try await loadAppIdManifest()
  await cachedAppIdManifest.set(manifest)
  return manifest
}

func clearCachedAppIdManifest() async {
  await cachedAppIdManifest.clear()
}

// implementation

private actor CachedAppIdManifest {
  private var appIdManifest: AppIdManifest?

  func clear() {
    self.appIdManifest = nil
  }

  func get() -> AppIdManifest? {
    self.appIdManifest
  }

  func set(_ appIdManifest: AppIdManifest) {
    self.appIdManifest = appIdManifest
  }
}

private let cachedAppIdManifest = CachedAppIdManifest()

private func loadAppIdManifest() async throws -> AppIdManifest {
  let apps = try await Current.db.query(IdentifiedApp.self).all()
  let bundleIds = try await Current.db.query(AppBundleId.self).all()
  let categories = try await Current.db.query(AppCategory.self).all()

  apps.forEach { app in
    let ids = bundleIds.filter { $0.identifiedAppId == app.id }
    app.bundleIds = .loaded(ids)
    if let categoryId = app.categoryId {
      app.category = .loaded(categories.first { $0.id == categoryId })
    }
  }

  var manifest = AppIdManifest()
  for category in categories {
    manifest.categories[category.slug] = []
  }

  for app in apps {
    manifest.displayNames[app.slug] = app.name
    manifest.apps[app.slug] = Set(try app.bundleIds.models.map(\.bundleId))
    if let cat = try? app.category.model {
      manifest.categories[cat.slug]?.insert(app.slug)
    }
  }

  await cachedAppIdManifest.set(manifest)
  return manifest
}
