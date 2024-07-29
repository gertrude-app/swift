import Duet
import Tagged

struct AdminToken: Codable, Sendable {
  var id: Id
  var adminId: Admin.Id
  var value: Value
  var createdAt = Date()
  var deletedAt: Date

  init(
    id: Id = .init(),
    value: Value = .init(Current.uuid()),
    adminId: Admin.Id,
    deletedAt: Date? = nil
  ) {
    self.id = id
    self.value = value
    self.adminId = adminId
    self.deletedAt = deletedAt ?? Date(addingDays: 28)
  }
}

// extensions

extension AdminToken {
  typealias Value = Tagged<(AdminToken, value: ()), UUID>
}
