import DuetSQL
import Tagged

final class Thing: Codable {
  enum CustomEnum: String, Codable {
    case foo
    case bar
  }

  var id: Id
  var string: String
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
    id: Id = .init(),
    string: String = "foo",
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
      .string: .string(string),
      .int: .int(int),
      .bool: .bool(bool),
      .optionalInt: .int(optionalInt),
      .optionalString: .string(optionalString),
      .customEnum: .enum(customEnum),
      .optionalCustomEnum: .enum(optionalCustomEnum),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }

  typealias ColumnName = CodingKeys

  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case string
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
      return .string(string)
    case .int:
      return .int(int)
    case .bool:
      return .bool(bool)
    case .optionalInt:
      return .int(optionalInt)
    case .optionalString:
      return .string(optionalString)
    case .customEnum:
      return .enum(customEnum)
    case .optionalCustomEnum:
      return .enum(optionalCustomEnum)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    case .deletedAt:
      return .date(deletedAt)
    }
  }
}
