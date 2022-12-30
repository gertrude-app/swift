import Foundation
import TypescriptPairQL

struct GetIdentifiedApps: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct App: TypescriptPairOutput {
    struct BundleId: TypescriptNestable {
      let id: UUID
      let bundleId: String
    }

    struct Category: TypescriptNestable {
      let id: UUID
      let name: String
      let slug: String
    }

    let id: UUID
    let name: String
    let slug: String
    let selectable: Bool
    var bundleIds: [BundleId]
    let category: Category?
  }

  typealias Output = [App]
}

// resolver

extension GetIdentifiedApps: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    async let apps = Current.db.query(IdentifiedApp.self).all()
    async let categories = Current.db.query(AppCategory.self).all()
    async let bundleIds = Current.db.query(AppBundleId.self).all()

    let categoryMap: [AppCategory.Id: App.Category] = (try await categories)
      .reduce(into: [:]) { $0[$1.id] = .init(from: $1) }

    var appMap: [IdentifiedApp.Id: App] = (try await apps)
      .reduce(into: [:]) { map, identifiedApp in
        map[identifiedApp.id] = .init(
          id: identifiedApp.id.rawValue,
          name: identifiedApp.name,
          slug: identifiedApp.slug,
          selectable: identifiedApp.selectable,
          bundleIds: [],
          category: categoryMap[identifiedApp.categoryId ?? .init()]
        )
      }

    for bundleId in try await bundleIds {
      appMap[bundleId.identifiedAppId]?.bundleIds.append(.init(from: bundleId))
    }

    return Array(appMap.values)
  }
}

// extensions

extension GetIdentifiedApps.App.Category {
  init(from appCategory: AppCategory) {
    id = appCategory.id.rawValue
    name = appCategory.name
    slug = appCategory.slug
  }
}

extension GetIdentifiedApps.App.BundleId {
  init(from appBundleId: AppBundleId) {
    id = appBundleId.id.rawValue
    bundleId = appBundleId.bundleId
  }
}
