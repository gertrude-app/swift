import Duet
import Gertie

struct BlockedApp: Codable, Sendable {
  var id: Id
  var appId: IdentifiedApp.Id
  var userId: User.Id
  var schedule: RuleSchedule?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    appId: IdentifiedApp.Id,
    userId: User.Id,
    schedule: RuleSchedule? = nil
  ) {
    self.id = id
    self.appId = appId
    self.userId = userId
    self.schedule = schedule
  }
}
