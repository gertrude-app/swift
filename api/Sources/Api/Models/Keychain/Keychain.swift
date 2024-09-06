import DuetSQL

struct Keychain: Codable, Sendable {
  var id: Id
  var authorId: Admin.Id
  var name: String
  var description: String?
  var isPublic: Bool
  var createdAt = Date()
  var updatedAt = Date()

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
    try await Key.query()
      .where(.keychainId == self.id)
      .all()
  }
}
