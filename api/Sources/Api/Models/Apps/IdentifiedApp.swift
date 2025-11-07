import DuetSQL

struct IdentifiedApp: Codable, Sendable {
  var id: Id
  var categoryId: AppCategory.Id?
  var name: String
  var slug: String
  var launchable: Bool
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    categoryId: AppCategory.Id? = nil,
    name: String,
    slug: String,
    launchable: Bool,
  ) {
    self.id = id
    self.categoryId = categoryId
    self.name = name
    self.slug = slug
    self.launchable = launchable
  }
}

// loaders

extension IdentifiedApp {
  func bundleIds(in db: any DuetSQL.Client) async throws -> [AppBundleId] {
    try await AppBundleId.query()
      .where(.identifiedAppId == self.id)
      .all(in: db)
  }
}
