import Duet
import Foundation
import XCore

public protocol Model: Duet.Identifiable, Codable, Sendable {
  associatedtype ColumnName: CodingKey, Hashable, CaseIterable, ModelColumns
  static func columnName(_ column: ColumnName) -> String
  static var tableName: String { get }
  static var schemaName: String { get }
  var insertValues: [ColumnName: Postgres.Data] { get }
  func postgresData(for: ColumnName) -> Postgres.Data
}

public protocol ModelColumns {
  static var id: Self { get }
  static var createdAt: Self { get }
}

public extension Model {
  static func query() -> DuetQuery<Self> {
    DuetQuery()
  }

  static var schemaName: String {
    "public"
  }

  static func column(_ name: String) throws -> ColumnName {
    for column in ColumnName.allCases {
      if Self.columnName(column) == name {
        return column
      }
    }
    throw DuetSQLError.missingExpectedColumn(name)
  }

  static var isSoftDeletable: Bool {
    (try? Self.column("deleted_at")) != nil
  }

  static var qualifiedTableName: String {
    "\(schemaName).\(tableName)"
  }
}

public extension Model where ColumnName: RawRepresentable, ColumnName.RawValue == String {
  static func columnName(_ column: ColumnName) -> String {
    column.rawValue.snakeCased
  }

  static subscript(_ column: ColumnName) -> String {
    self.columnName(column)
  }
}

extension Model where IdValue: RawRepresentable, IdValue.RawValue == UUID {
  var uuidId: UUID { id.rawValue }
}
