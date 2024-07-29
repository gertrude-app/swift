import Duet
import Foundation

public protocol Model: Duet.Identifiable, Codable, Sendable {
  associatedtype ColumnName: CodingKey, Hashable, CaseIterable
  static func columnName(_ column: ColumnName) -> String
  static var tableName: String { get }
  var insertValues: [ColumnName: Postgres.Data] { get }
  func postgresData(for: ColumnName) -> Postgres.Data
}

public extension Model {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  static func column(_ name: String) throws -> ColumnName {
    for column in ColumnName.allCases {
      if Self.columnName(column) == name {
        return column
      }
    }
    throw DuetSQLError.missingExpectedColumn(name)
  }

  func satisfies(constraint: SQL.WhereConstraint<Self>) -> Bool {
    constraint.isSatisfied(by: self)
  }
}

public extension Model where ColumnName: RawRepresentable, ColumnName.RawValue == String {
  static func columnName(_ column: ColumnName) -> String {
    column.rawValue.snakeCased
  }

  static subscript(_ column: ColumnName) -> String {
    columnName(column)
  }
}

extension Model where IdValue: RawRepresentable, IdValue.RawValue == UUID {
  var uuidId: UUID { id.rawValue }
}

extension Model {
  func introspectValue(at column: String) throws -> Any {
    let mirror = Mirror(reflecting: self)
    for child in mirror.children {
      if child.label == column {
        return child.value
      }
    }
    return DuetSQLError.missingExpectedColumn(column)
  }
}

public extension Array where Element: Model {
  mutating func order<M: Model>(by order: SQL.Order<M>) throws {
    try sort { a, b in
      let propA = try a.introspectValue(at: order.column.stringValue)
      let propB = try b.introspectValue(at: order.column.stringValue)
      switch (propA, propB) {
      case (let dateA, let dateB) as (Date, Date):
        return order.direction == .asc ? dateA < dateB : dateA > dateB
      case (let intA, let intB) as (Int, Int):
        return order.direction == .asc ? intA < intB : intA > intB
      default:
        throw DuetSQLError
          .notImplemented("[DuetSQL.Model].order(by:) not implemented for \(type(of: propA))")
      }
    }
  }
}
