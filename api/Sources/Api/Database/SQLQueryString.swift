import FluentSQL
import Foundation

extension SQLQueryString {
  mutating func appendInterpolation(table Migration: TableNamingMigration.Type) {
    appendInterpolation(raw: Migration.tableName)
  }

  mutating func appendInterpolation(constraint: Constraint) {
    appendInterpolation(raw: #""\#(constraint.name)""#)
  }

  mutating func appendInterpolation(type: ColumnType) {
    appendInterpolation(raw: type.sql)
  }
}
