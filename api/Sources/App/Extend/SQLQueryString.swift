import FluentSQL
import Foundation

extension SQLQueryString {
  mutating func appendInterpolation(table Migration: TableNamingMigration.Type) {
    appendInterpolation(raw: Migration.tableName)
  }

  mutating func appendInterpolation(type: SQLType) {
    appendInterpolation(raw: type.rawValue)
  }

  mutating func appendInterpolation(foreignKey: ForeignKey) {
    appendInterpolation(raw: foreignKey.name)
  }

  enum Constraint {
    case notNull
    case primaryKey

    var sql: String {
      switch self {
      case .notNull:
        return "NOT NULL"
      case .primaryKey:
        return "PRIMARY KEY"
      }
    }
  }

  mutating func appendInterpolation(constraint: Constraint) {
    appendInterpolation(raw: constraint.sql)
  }
}
