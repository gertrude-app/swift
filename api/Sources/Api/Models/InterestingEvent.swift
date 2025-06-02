import Foundation

struct InterestingEvent: Codable, Sendable {
  var id: Id
  var eventId: String
  var kind: String
  var context: String
  var computerUserId: ComputerUser.Id?
  var parentId: Admin.Id?
  var detail: String?
  var createdAt = Date()

  init(
    id: Id = .init(),
    eventId: String,
    kind: String,
    context: String,
    computerUserId: ComputerUser.Id? = nil,
    parentId: Admin.Id? = nil,
    detail: String? = nil
  ) {
    self.id = id
    self.eventId = eventId
    self.kind = kind
    self.context = context
    self.computerUserId = computerUserId
    self.parentId = parentId
    self.detail = detail
  }
}
