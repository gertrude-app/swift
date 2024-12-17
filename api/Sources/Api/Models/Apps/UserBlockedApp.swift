import DuetSQL
import Gertie

struct UserBlockedApp: Codable, Sendable {
  var id: Id
  var identifier: String
  var userId: User.Id
  var schedule: RuleSchedule?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    identifier: String,
    userId: User.Id,
    schedule: RuleSchedule? = nil
  ) {
    self.id = id
    self.identifier = identifier
    self.userId = userId
    self.schedule = schedule
  }
}

// extensions

extension UserBlockedApp {
  var dto: DTO {
    DTO(id: self.id, identifier: self.identifier, schedule: self.schedule)
  }

  struct DTO: Codable, Equatable, Sendable {
    var id: Id
    var identifier: String
    var schedule: RuleSchedule?

    init(
      id: Id = .init(),
      identifier: String,
      schedule: RuleSchedule? = nil
    ) {
      self.id = id
      self.identifier = identifier
      self.schedule = schedule
    }
  }
}

extension UserBlockedApp {
  var blockedApp: BlockedApp {
    BlockedApp(identifier: self.identifier, schedule: self.schedule)
  }

  init(dto: DTO, userId: User.Id) {
    self.init(id: dto.id, identifier: dto.identifier, userId: userId, schedule: dto.schedule)
  }
}
