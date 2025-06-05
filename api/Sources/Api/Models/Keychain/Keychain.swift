import DuetSQL

struct Keychain: Codable, Sendable {
  var id: Id
  var parentId: Parent.Id
  var name: String
  var description: String?
  var warning: String?
  var isPublic: Bool
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    parentId: Parent.Id,
    name: String,
    isPublic: Bool = false,
    description: String? = nil,
    warning: String? = nil
  ) {
    self.id = id
    self.parentId = parentId
    self.name = name
    self.isPublic = isPublic
    self.description = description
    self.warning = warning
  }
}

// loaders

extension Keychain {
  func keys(in db: any DuetSQL.Client) async throws -> [Key] {
    try await Key.query()
      .where(.keychainId == self.id)
      .all(in: db)
  }
}
