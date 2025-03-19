import Dependencies
import Foundation
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
  @Dependency(\.db) var db
  let apps = try await db.select(all: IdentifiedApp.self)
  let bundleIds = try await db.select(all: AppBundleId.self)
  let categories = try await db.select(all: AppCategory.self)

  struct AppData {
    let bundleIds: [AppBundleId]
    let category: AppCategory?
  }

  var appData: [IdentifiedApp.Id: AppData] = [:]

  for app in apps {
    let ids = bundleIds.filter { $0.identifiedAppId == app.id }
    appData[app.id] = AppData(
      bundleIds: ids,
      category: app.categoryId
        .flatMap { cid in categories.first { $0.id == cid } }
    )
  }

  var manifest = AppIdManifest()
  for category in categories {
    manifest.categories[category.slug] = []
  }

  for app in apps {
    manifest.displayNames[app.slug] = app.name
    let data = appData[app.id]!
    manifest.apps[app.slug] = Set(data.bundleIds.map(\.bundleId))
    if let category = data.category {
      manifest.categories[category.slug]?.insert(app.slug)
    }
  }

  await cachedAppIdManifest.set(manifest)
  return manifest
}
