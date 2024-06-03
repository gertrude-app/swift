import FluentSQL
import Foundation

extension SQLQueryString {
  mutating func appendInterpolation(table Migration: TableNamingMigration.Type) {
    self.appendInterpolation(raw: Migration.tableName)
  }

  mutating func appendInterpolation(constraint: Constraint) {
    self.appendInterpolation(raw: #""\#(constraint.name)""#)
  }

  mutating func appendInterpolation(type: ColumnType) {
    self.appendInterpolation(raw: type.sql)
  }
}
