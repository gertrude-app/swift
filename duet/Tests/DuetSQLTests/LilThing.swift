import DuetSQL
import Foundation
import Tagged

struct LilThing: Codable {
  var id: Id
  var int: Int
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  init(
    id: Id = .init(UUID()),
    int: Int = 123,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    deletedAt: Date? = nil
  ) {
    self.id = id
    self.int = int
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.deletedAt = deletedAt
  }
}

struct OptLilThing: Codable {
  var id: Id
  var int: Int?
  var string: String?
  var createdAt = Date()

  init(id: Id = .init(UUID()), int: Int? = nil, string: String? = nil) {
    self.id = id
    self.int = int
    self.string = string
  }
}

// extensions

extension LilThing {
  var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .int: .int(self.int),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }

  typealias ColumnName = CodingKeys

  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case int
    case createdAt
    case updatedAt
    case deletedAt
  }
}

extension LilThing: Model {
  typealias Id = Tagged<LilThing, UUID>
  static let tableName = "lil_things"

  func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .int:
      return .int(self.int)
    case .createdAt:
      return .date(self.createdAt)
    case .updatedAt:
      return .date(self.updatedAt)
    case .deletedAt:
      return .date(self.deletedAt)
    }
  }
}

extension OptLilThing {
  var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .int: .int(self.int),
      .string: .string(self.string),
      .createdAt: .currentTimestamp,
    ]
  }

  typealias ColumnName = CodingKeys

  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case int
    case string
    case createdAt
  }
}

extension OptLilThing: Model {
  typealias Id = Tagged<OptLilThing, UUID>
  static let tableName = "opt_lil_things"

  func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .int:
      return .int(self.int)
    case .string:
      return .string(self.string)
    case .createdAt:
      return .date(self.createdAt)
    }
  }
}
