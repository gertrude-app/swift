import Duet

struct IdentifiedApp: Codable, Sendable {
  var id: Id
  var categoryId: AppCategory.Id?
  var bundleName: String?
  var localizedName: String?
  var customName: String?
  var slug: String
  var launchable: Bool
  var createdAt = Date()
  var updatedAt = Date()

  var name: String {
    self.bundleName ?? self.localizedName ?? self.customName!
  }

  init(
    id: Id = .init(),
    categoryId: AppCategory.Id? = nil,
    bundleName: String? = nil,
    localizedName: String? = nil,
    customName: String? = nil,
    slug: String,
    launchable: Bool
  ) {
    // NB: this is also enforced by a custom database check constraint
    precondition(
      !(bundleName == nil && localizedName == nil && customName == nil),
      "At least one of `bundleName`, `localizedName`, or `customName` must be non-nil"
    )
    self.id = id
    self.categoryId = categoryId
    self.bundleName = bundleName
    self.localizedName = localizedName
    self.customName = customName
    self.slug = slug
    self.launchable = launchable
  }
}
