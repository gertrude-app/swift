import Duet

struct UserKeychain: Codable, Sendable {
  var id: Id
  var userId: User.Id
  var keychainId: Keychain.Id
  var createdAt = Date()

  init(id: Id = .init(), userId: User.Id, keychainId: Keychain.Id) {
    self.id = id
    self.userId = userId
    self.keychainId = keychainId
  }
}
