import Duet
import Tagged

final class AdminToken: Codable {
  var id: Id
  var adminId: Admin.Id
  var value: Value
  var createdAt = Date()
  var deletedAt: Date

  var admin = Parent<Admin>.notLoaded

  init(
    id: Id = .init(),
    value: Value = .init(rawValue: UUID.new()),
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
