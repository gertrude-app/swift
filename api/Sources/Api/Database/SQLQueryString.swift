import FluentSQL
import Foundation

extension SQLQueryString {
  mutating func appendInterpolation(table Migration: TableNamingMigration.Type) {
    self.appendInterpolation(unsafeRaw: Migration.tableName)
  }

  mutating func appendInterpolation(constraint: Constraint) {
    self.appendInterpolation(unsafeRaw: #""\#(constraint.name)""#)
  }

  mutating func appendInterpolation(type: ColumnType) {
    self.appendInterpolation(unsafeRaw: type.sql)
  }
}
