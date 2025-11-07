import DuetSQL
import Fluent

public enum ColumnType {
  case text
  case uuid
  case date
  case int
  case bigint
  case boolean
  case jsonb
  case varchar(Int)
  case custom(String)
  case timestampWithTimezone

  static func `enum`<T: PostgresEnum & CaseIterable>(_: T.Type) -> ColumnType {
    .custom(T.typeName)
  }

  var sql: String {
    switch self {
    case .text: "text"
    case .uuid: "uuid"
    case .date: "date"
    case .int: "int"
    case .bigint: "bigint"
    case .boolean: "boolean"
    case .jsonb: "jsonb"
    case .varchar(let length): "varchar(\(length))"
    case .timestampWithTimezone: "timestamp with time zone"
    case .custom(let type): type
    }
  }
}

struct Column {
  enum Default {
    case boolean(Bool)
    case text(String)
    case int(Int)
    case enumValue(PostgresEnum)
    case uuid(UUID)
    case currentTimestamp

    var sql: String {
      switch self {
      case .boolean(let value):
        value ? "TRUE" : "FALSE"
      case .text(let value):
        "'\(value)'"
      case .int(let value):
        "\(value)"
      case .uuid(let value):
        "'\(value)'"
      case .enumValue(let value):
        "'\(value.rawValue)'::\(value.typeName)"
      case .currentTimestamp:
        "CURRENT_TIMESTAMP"
      }
    }
  }

  enum Constraint {
    case notNull
    case nullable
    case unique
    case primaryKey

    var sql: String {
      switch self {
      case .notNull:
        "NOT NULL"
      case .nullable:
        ""
      case .primaryKey:
        "PRIMARY KEY"
      case .unique:
        "UNIQUE"
      }
    }
  }

  var name: FieldKey
  var type: ColumnType
  var constraints: [Constraint]
  var defaultValue: Default?

  var sql: String {
    var sql = "\"\(name)\" \(type.sql)"
    // all columns are NOT NULL by default, unless explicitly set to nullable
    if !self.constraints.contains(.nullable) {
      sql += " NOT NULL"
    }
    let withoutNull = self.constraints.filter { $0 != .nullable && $0 != .notNull }
    if !withoutNull.isEmpty {
      sql += " \(self.constraints.map(\.sql).joined(separator: " "))"
    }
    if let defaultValue {
      sql += " DEFAULT \(defaultValue.sql)"
    }
    return sql
  }
}

extension Column {
  init(
    _ name: FieldKey,
    _ type: ColumnType,
    _ constraint: Constraint = .notNull,
    default: Default? = nil,
  ) {
    self.name = name
    self.type = type
    self.constraints = [constraint]
    self.defaultValue = `default`
  }

  init(
    _ name: FieldKey,
    _ type: ColumnType,
    _ constraints: [Constraint],
    default: Default? = nil,
  ) {
    self.name = name
    self.type = type
    self.constraints = constraints
    self.defaultValue = `default`
  }
}

@resultBuilder
enum ColumnBuilder {
  static func buildBlock(_ columns: Column...) -> [Column] {
    columns
  }
}
