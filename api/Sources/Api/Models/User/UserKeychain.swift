import Duet
import Gertie

struct UserKeychain: Codable, Sendable {
  var id: Id
  var userId: User.Id
  var keychainId: Keychain.Id
  var schedule: KeychainSchedule?
  var createdAt = Date()

  init(
    id: Id = .init(),
    userId: User.Id,
    keychainId: Keychain.Id,
    schedule: KeychainSchedule? = nil
  ) {
    self.id = id
    self.userId = userId
    self.keychainId = keychainId
    self.schedule = schedule
  }
}
