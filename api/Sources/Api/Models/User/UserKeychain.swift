import Duet

final class UserKeychain: Codable {
  var id: Id
  var userId: User.Id
  var keychainId: Keychain.Id
  var createdAt = Date()

  var user = Parent<User>.notLoaded
  var keychain = Parent<Keychain>.notLoaded

  init(id: Id = .init(), userId: User.Id, keychainId: Keychain.Id) {
    self.id = id
    self.userId = userId
    self.keychainId = keychainId
  }
}
