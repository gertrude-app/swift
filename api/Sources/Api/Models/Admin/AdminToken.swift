import Dependencies
import Duet
import Tagged

struct AdminToken: Codable, Sendable {
  var id: Id
  var parentId: Admin.Id
  var value: Value
  var createdAt = Date()
  var deletedAt: Date

  init(
    id: Id? = nil,
    value: Value? = nil,
    parentId: Admin.Id,
    deletedAt: Date? = nil
  ) {
    @Dependency(\.uuid) var uuid
    self.id = id ?? .init(uuid())
    self.value = value ?? .init(uuid())
    self.parentId = parentId
    self.deletedAt = deletedAt ?? Date(addingDays: 28)
  }
}

// extensions

extension AdminToken {
  typealias Value = Tagged<(AdminToken, value: ()), UUID>
}
