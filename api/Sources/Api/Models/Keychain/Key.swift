import Duet
import Gertie

struct Key: Codable, Sendable {
  var id: Id
  var keychainId: Keychain.Id
  var key: Gertie.Key
  var comment: String?
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

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
    try await Keychain.find(self.keychainId)
  }
}
