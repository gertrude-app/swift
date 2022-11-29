import Duet

final class Key: Codable {
  var id: Id
  var keychainId: Keychain.Id
  var key: Key
  var comment: String?
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  var keychain = Parent<Keychain>.notLoaded

  init(
    id: Id = .init(),
    keychainId: Keychain.Id,
    key: Key,
    comment: String? = nil,
    deletedAt: Date? = nil
  ) {
    self.id = id
    self.keychainId = keychainId
    self.key = key
    self.comment = comment
    self.deletedAt = deletedAt
  }
}
