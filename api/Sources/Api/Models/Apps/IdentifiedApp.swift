import Duet

struct IdentifiedApp: Codable, Sendable {
  var id: Id
  var categoryId: AppCategory.Id?
  var name: String
  var slug: String
  var selectable: Bool
  var description: String?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    categoryId: AppCategory.Id? = nil,
    name: String,
    slug: String,
    selectable: Bool,
    description: String? = nil
  ) {
    self.id = id
    self.categoryId = categoryId
    self.name = name
    self.slug = slug
    self.selectable = selectable
    self.description = description
  }
}
