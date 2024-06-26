import Duet
import Gertie

final class Key: Codable {
  var id: Id
  var keychainId: Keychain.Id
  var key: Gertie.Key
  var comment: String?
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  var keychain = Parent<Keychain>.notLoaded

  init(
    id: Id = .init(),
    keychainId: Keychain.Id,
    key: Gertie.Key,
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

// loaders

extension Key {
  func keychain() async throws -> Keychain {
    try await self.keychain.useLoaded(or: {
      try await Current.db.find(keychainId)
    })
  }
}
