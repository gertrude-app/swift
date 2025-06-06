import Foundation
import PairQL

struct GetIdentifiedApps: Pair {
  static let auth: ClientAuth = .parent

  struct App: PairOutput {
    struct BundleId: PairNestable {
      let id: AppBundleId.Id
      let bundleId: String
    }

    struct Category: PairNestable {
      let id: AppCategory.Id
      let name: String
      let slug: String
    }

    let id: IdentifiedApp.Id
    let name: String
    let slug: String
    let launchable: Bool
    var bundleIds: [BundleId]
    let category: Category?
  }

  typealias Output = [App]
}

// resolver

extension GetIdentifiedApps: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    // TODO: why aren't i using the cached app id manifest?
    async let apps = try await context.db.select(all: IdentifiedApp.self)
    async let bundleIds = try await context.db.select(all: AppBundleId.self)
    async let categories = try await context.db.select(all: AppCategory.self)

    let categoryMap: [AppCategory.Id: App.Category] = try await (categories)
      .reduce(into: [:]) { $0[$1.id] = .init(from: $1) }

    var appMap: [IdentifiedApp.Id: App] = try await (apps)
      .reduce(into: [:]) { map, identifiedApp in
        map[identifiedApp.id] = .init(
          id: identifiedApp.id,
          name: identifiedApp.name,
          slug: identifiedApp.slug,
          launchable: identifiedApp.launchable,
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
    id = appCategory.id
    name = appCategory.name
    slug = appCategory.slug
  }
}

extension GetIdentifiedApps.App.BundleId {
  init(from appBundleId: AppBundleId) {
    id = appBundleId.id
    bundleId = appBundleId.bundleId
  }
}
