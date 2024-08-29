import Dependencies
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
    value: Value? = nil,
    adminId: Admin.Id,
    deletedAt: Date? = nil
  ) {
    @Dependency(\.uuid) var uuid
    self.id = id
    self.value = value ?? .init(uuid())
    self.adminId = adminId
    self.deletedAt = deletedAt ?? Date(addingDays: 28)
  }
}

// extensions

extension AdminToken {
  typealias Value = Tagged<(AdminToken, value: ()), UUID>
}
