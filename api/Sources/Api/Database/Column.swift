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
    case .text: return "text"
    case .uuid: return "uuid"
    case .date: return "date"
    case .int: return "int"
    case .bigint: return "bigint"
    case .boolean: return "boolean"
    case .jsonb: return "jsonb"
    case .varchar(let length): return "varchar(\(length))"
    case .timestampWithTimezone: return "timestamp with time zone"
    case .custom(let type): return type
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

    public var sql: String {
      switch self {
      case .boolean(let value):
        return value ? "TRUE" : "FALSE"
      case .text(let value):
        return "'\(value)'"
      case .int(let value):
        return "\(value)"
      case .uuid(let value):
        return "'\(value)'"
      case .enumValue(let value):
        return "'\(value.rawValue)'::\(value.typeName)"
      case .currentTimestamp:
        return "CURRENT_TIMESTAMP"
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
        return "NOT NULL"
      case .nullable:
        return ""
      case .primaryKey:
        return "PRIMARY KEY"
      case .unique:
        return "UNIQUE"
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
    if let defaultValue = defaultValue {
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
    default: Default? = nil
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
    default: Default? = nil
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
