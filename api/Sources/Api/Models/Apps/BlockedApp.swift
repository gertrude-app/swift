import DuetSQL
import struct Gertie.RuleSchedule

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

// loaders

extension BlockedApp {
  func identifiedApp(in db: any DuetSQL.Client) async throws -> IdentifiedApp {
    try await IdentifiedApp.query()
      .where(.id == self.appId)
      .first(in: db)
  }
}
