import Duet
import Gertie

struct ChildKeychain: Codable, Sendable {
  var id: Id
  var childId: User.Id
  var keychainId: Keychain.Id
  var schedule: RuleSchedule?
  var createdAt = Date()

  init(
    id: Id = .init(),
    childId: User.Id,
    keychainId: Keychain.Id,
    schedule: RuleSchedule? = nil
  ) {
    self.id = id
    self.childId = childId
    self.keychainId = keychainId
    self.schedule = schedule
  }
}
