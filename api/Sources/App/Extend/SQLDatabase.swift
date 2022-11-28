import DuetSQL
import FluentSQL

public extension SQLDatabase {
  @discardableResult
  func execute(_ sql: SQLQueryString) async throws -> [SQLRow] {
    try await raw(sql).all()
  }

  func renameTable(
    from Old: TableNamingMigration.Type,
    to New: TableNamingMigration.Type
  ) async throws {
    try await execute("""
      ALTER TABLE \(table: Old)
      RENAME TO \(table: New)
    """)
  }

  func dropTable(_ table: TableNamingMigration.Type) async throws {
    try await execute("DROP TABLE \(table: table)")
  }

  func renameColumn(
    on Migration: TableNamingMigration.Type,
    from old: FieldKey,
    to new: FieldKey
  ) async throws {
    try await execute("""
      ALTER TABLE \(table: Migration.self)
      RENAME COLUMN \(col: old) TO \(col: new)
    """)
  }

  func dropColumn(
    _ column: FieldKey,
    on Migration: TableNamingMigration.Type
  ) async throws {
    try await execute("""
      ALTER TABLE \(table: Migration.self)
      DROP COLUMN \(col: column)
    """)
  }

  func addColumn(
    _ column: FieldKey,
    on Migration: TableNamingMigration.Type,
    type: SQLType,
    nullable: Bool = false,
    default: SQLColumnDefault? = nil
  ) async throws {
    let nullConstraint = nullable ? "" : " NOT NULL"
    let defaultValue = `default`.map { " DEFAULT \($0.sql)" } ?? ""
    try await execute("""
      ALTER TABLE \(table: Migration.self)
      ADD COLUMN \(col: column) \(raw: type.rawValue)\(raw: nullConstraint)\(raw: defaultValue)
    """)
  }

  func addForeignKey(_ key: ForeignKey) async throws {
    try await execute("""
      ALTER TABLE \(table: key.table)
      ADD CONSTRAINT \(foreignKey: key)
        FOREIGN KEY (\(col: key.column))
        REFERENCES \(table: key.referencedTable) (\(col: .id))
    """)
  }

  func dropForeignKey(_ key: ForeignKey) async throws {
    try await execute("""
      ALTER TABLE \(table: key.table)
      DROP CONSTRAINT \(foreignKey: key)
    """)
  }

  func addNotNullConstraint(
    to column: FieldKey,
    on Migration: TableNamingMigration.Type
  ) async throws {
    try await execute("""
      ALTER TABLE \(table: Migration.self)
      ALTER COLUMN \(col: column) SET NOT NULL
    """)
  }

  func dropNotNullConstraint(
    from column: FieldKey,
    on Migration: TableNamingMigration.Type
  ) async throws {
    try await execute("""
      ALTER TABLE \(table: Migration.self)
      ALTER COLUMN \(col: column) DROP NOT NULL
    """)
  }

  func addUniqueConstraint(_ constraint: UniqueConstraint) async throws {
    let columns = constraint.columns.map(\.description).joined(separator: ", ")
    try await execute("""
      ALTER TABLE \(table: constraint.table)
      ADD CONSTRAINT \(raw: constraint.name) UNIQUE (\(raw: columns))
    """)
  }

  func dropUniqueConstraint(_ constraint: UniqueConstraint) async throws {
    try await execute("""
      ALTER TABLE \(table: constraint.table)
      DROP CONSTRAINT \(raw: constraint.name)
    """)
  }

  func dropDefault(from column: FieldKey, on Migration: TableNamingMigration.Type) async throws {
    try await execute("""
      ALTER TABLE \(table: Migration.self)
      ALTER COLUMN \(col: column)
      DROP DEFAULT
    """)
  }
}

public enum SQLType: String {
  case text
  case uuid
  case date
  case bigint
  case boolean
  case jsonb
  case timestampWithTimezone = "timestamp with time zone"
}

public enum SQLColumnDefault {
  case boolean(Bool)
  case text(String)

  public var sql: String {
    switch self {
    case .boolean(let value):
      return value ? "TRUE" : "FALSE"
    case .text(let value):
      return "'\(value)'"
    }
  }
}
