import Dependencies
import Duet
import Tagged

extension Parent {
  struct DashToken: Codable, Sendable {
    var id: Id
    var parentId: Parent.Id
    var value: Value
    var createdAt = Date()
    var deletedAt: Date

    init(
      id: Id? = nil,
      value: Value? = nil,
      parentId: Parent.Id,
      deletedAt: Date? = nil,
    ) {
      @Dependency(\.uuid) var uuid
      self.id = id ?? .init(uuid())
      self.value = value ?? .init(uuid())
      self.parentId = parentId
      self.deletedAt = deletedAt ?? Date(addingDays: 28)
    }
  }
}

// extensions

extension Parent.DashToken {
  typealias Value = Tagged<(Parent.DashToken, value: ()), UUID>
}
