import Dependencies
import Duet
import DuetSQL
import Tagged

struct SuperAdminToken: Codable, Sendable {
  var id: Id
  var value: Value
  var createdAt = Date()
  var deletedAt: Date

  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case value
    case createdAt
    case deletedAt
  }

  init(id: Id? = nil, value: Value? = nil, deletedAt: Date? = nil) {
    @Dependency(\.uuid) var uuid
    self.id = id ?? .init(uuid())
    self.value = value ?? .init(uuid())
    self.deletedAt = deletedAt ?? Date(addingDays: 60)
  }
}

extension SuperAdminToken {
  typealias Id = Tagged<SuperAdminToken, UUID>
  typealias Value = Tagged<(SuperAdminToken, value: ()), UUID>
}
