import DuetSQL

final class Keychain: Codable {
  var id: Id
  var authorId: Admin.Id
  var name: String
  var description: String?
  var isPublic: Bool
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  var author = Parent<Admin>.notLoaded
  var keys = Children<Key>.notLoaded
  var users = Siblings<User>.notLoaded

  init(
    id: Id = .init(),
    authorId: Admin.Id,
    name: String,
    isPublic: Bool = false,
    description: String? = nil
  ) {
    self.id = id
    self.authorId = authorId
    self.name = name
    self.isPublic = isPublic
    self.description = description
  }
}

// loaders

extension Keychain {
  func keys() async throws -> [Key] {
    try await self.keys.useLoaded(or: {
      try await Current.db.query(Key.self)
        .where(.keychainId == id)
        .all()
    })
  }
}
