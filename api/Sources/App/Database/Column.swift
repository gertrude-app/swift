import DuetSQL
import Fluent

public enum ColumnType {
  case text
  case uuid
  case date
  case bigint
  case boolean
  case jsonb
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
    case .bigint: return "bigint"
    case .boolean: return "boolean"
    case .jsonb: return "jsonb"
    case .timestampWithTimezone: return "timestamp with time zone"
    case .custom(let type): return type
    }
  }
}

struct Column {
  enum Default {
    case boolean(Bool)
    case text(String)
    case enumValue(PostgresEnum)

    public var sql: String {
      switch self {
      case .boolean(let value):
        return value ? "TRUE" : "FALSE"
      case .text(let value):
        return "'\(value)'"
      case .enumValue(let value):
        return "'\(value.rawValue)'::\(value.typeName)"
      }
    }
  }

  enum NullConstraint {
    case notNull
    case nullable

    var sql: String {
      switch self {
      case .notNull:
        return "NOT NULL"
      case .nullable:
        return "NULL"
      }
    }
  }

  var name: FieldKey
  var type: ColumnType
  var nullConstraint: NullConstraint
  var defaultValue: Default?

  var sql: String {
    var sql = "\(name) \(type.sql)"
    if nullConstraint == .notNull {
      sql += " NOT NULL"
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
    _ nullConstraint: Column.NullConstraint = .notNull,
    default: Column.Default? = nil
  ) {
    self.name = name
    self.type = type
    self.nullConstraint = nullConstraint
    defaultValue = `default`
  }
}
