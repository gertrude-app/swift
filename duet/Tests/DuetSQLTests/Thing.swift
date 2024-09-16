import DuetSQL
import Foundation
import Tagged

struct Thing: Codable {
  enum CustomEnum: String, Codable {
    case foo
    case bar
  }

  var id: Id
  var string: String
  var version: String
  var int: Int
  var bool: Bool
  var customEnum: CustomEnum
  var optionalCustomEnum: CustomEnum?
  var optionalInt: Int?
  var optionalString: String?
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  init(
    id: Id = .init(UUID()),
    string: String = "foo",
    version: String = "1.0.0",
    int: Int = 123,
    bool: Bool = true,
    customEnum: CustomEnum = .foo,
    optionalCustomEnum: CustomEnum? = nil,
    optionalInt: Int? = nil,
    optionalString: String? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    deletedAt: Date? = nil
  ) {
    self.id = id
    self.string = string
    self.version = version
    self.int = int
    self.bool = bool
    self.customEnum = customEnum
    self.optionalCustomEnum = optionalCustomEnum
    self.optionalInt = optionalInt
    self.optionalString = optionalString
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.deletedAt = deletedAt
  }
}

// extensions

extension Thing.CustomEnum: PostgresEnum {
  var typeName: String { "custom_enums" }
}

extension Thing {
  var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .string: .string(self.string),
      .version: .varchar(self.version),
      .int: .int(self.int),
      .bool: .bool(self.bool),
      .optionalInt: .int(self.optionalInt),
      .optionalString: .string(self.optionalString),
      .customEnum: .enum(self.customEnum),
      .optionalCustomEnum: .enum(self.optionalCustomEnum),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }

  typealias ColumnName = CodingKeys

  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case string
    case version
    case int
    case bool
    case optionalInt
    case optionalString
    case customEnum
    case optionalCustomEnum
    case createdAt
    case updatedAt
    case deletedAt
  }
}

extension Thing: Model {
  typealias Id = Tagged<Thing, UUID>
  static let tableName = "things"

  func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .string:
      return .string(self.string)
    case .version:
      return .varchar(self.version)
    case .int:
      return .int(self.int)
    case .bool:
      return .bool(self.bool)
    case .optionalInt:
      return .int(self.optionalInt)
    case .optionalString:
      return .string(self.optionalString)
    case .customEnum:
      return .enum(self.customEnum)
    case .optionalCustomEnum:
      return .enum(self.optionalCustomEnum)
    case .createdAt:
      return .date(self.createdAt)
    case .updatedAt:
      return .date(self.updatedAt)
    case .deletedAt:
      return .date(self.deletedAt)
    }
  }
}
