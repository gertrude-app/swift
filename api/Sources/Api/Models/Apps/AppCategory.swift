import Duet

final class AppCategory: Codable {
  var id: Id
  var name: String
  var slug: String
  var description: String?
  var createdAt = Date()
  var updatedAt = Date()

  var apps = Children<IdentifiedApp>.notLoaded

  init(
    id: Id = .init(),
    name: String,
    slug: String,
    description: String? = nil
  ) {
    self.id = id
    self.name = name
    self.slug = slug
    self.description = description
  }
}


