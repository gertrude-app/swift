import DuetSQL
import FluentSQL
import Vapor

extension SQLDatabase {
  @discardableResult
  func execute(_ sql: SQLQueryString) async throws -> [SQLRow] {
    if ProcessInfo.processInfo.environment["MIGRATE_LOG_SQL"] != nil {
      var serializer = SQLSerializer(database: self)
      sql.serialize(to: &serializer)
      print("\n\(serializer.sql)")
    }
    return try await raw(sql).all()
  }

  func create(
    table: TableNamingMigration.Type,
    @ColumnBuilder columns: () -> [Column]
  ) async throws {
    try await self.execute("""
      CREATE TABLE \(table: table) (
        \(unsafeRaw: columns().map(\.sql).joined(separator: ",\n    "))
      )
    """)
  }

  func renameTable(
    from Old: TableNamingMigration.Type,
    to New: TableNamingMigration.Type
  ) async throws {
    try await self.execute("""
      ALTER TABLE \(table: Old)
      RENAME TO \(table: New)
    """)
  }

  func drop(table: TableNamingMigration.Type) async throws {
    try await self.execute("DROP TABLE \(table: table)")
  }

  func renameColumn(
    on Migration: TableNamingMigration.Type,
    from old: FieldKey,
    to new: FieldKey
  ) async throws {
    try await self.execute("""
      ALTER TABLE \(table: Migration.self)
      RENAME COLUMN \(col: old) TO \(col: new)
    """)
  }

  func dropColumn(
    _ column: FieldKey,
    on Migration: TableNamingMigration.Type
  ) async throws {
    try await self.execute("""
      ALTER TABLE \(table: Migration.self)
      DROP COLUMN \(col: column)
    """)
  }

  func addColumn(
    _ column: FieldKey,
    on Migration: TableNamingMigration.Type,
    type: ColumnType,
    nullable: Bool = false,
    default: Column.Default? = nil
  ) async throws {
    let nullConstraint = nullable ? "" : " NOT NULL"
    let defaultValue = `default`.map { " DEFAULT \($0.sql)" } ?? ""
    try await self.execute("""
      ALTER TABLE \(table: Migration.self)
      ADD COLUMN \(col: column) \(type: type)\(unsafeRaw: nullConstraint)\(unsafeRaw: defaultValue)
    """)
  }

  func add(constraint: Constraint) async throws {
    try await self.execute(constraint.addSql)
  }

  func createIndex(on Migration: TableNamingMigration.Type, _ columns: FieldKey...) async throws {
    let colList = columns.map(\.description).joined(separator: ", ")
    try await self.execute("""
      CREATE INDEX \(unsafeRaw: self.idx(Migration, columns))
      ON \(table: Migration.self) (\(unsafeRaw: colList))
    """)
  }

  func dropIndex(on Migration: TableNamingMigration.Type, _ columns: FieldKey...) async throws {
    try await self.execute("""
      DROP INDEX IF EXISTS \(unsafeRaw: self.idx(Migration, columns))
    """)
  }

  private func idx(_ Migration: TableNamingMigration.Type, _ columns: [FieldKey]) -> String {
    "idx_\(Migration.tableName)_\(columns.map(\.description).joined(separator: "_"))"
  }

  func drop(constraint: Constraint) async throws {
    try await self.execute(constraint.dropSql)
  }

  func dropDefault(from column: FieldKey, on Migration: TableNamingMigration.Type) async throws {
    try await self.execute("""
      ALTER TABLE \(table: Migration.self)
      ALTER COLUMN \(col: column)
      DROP DEFAULT
    """)
  }

  func addDefault(
    of default: Column.Default,
    to column: FieldKey,
    on Migration: TableNamingMigration.Type
  ) async throws {
    try await self.execute("""
      ALTER TABLE \(table: Migration.self)
      ALTER COLUMN \(col: column)
      SET DEFAULT \(unsafeRaw: `default`.sql)
    """)
  }

  func create(enum Enum: (some PostgresEnum & RawRepresentable & CaseIterable).Type) async throws {
    try await self.execute("""
      CREATE TYPE \(unsafeRaw: Enum.typeName) AS ENUM (
        '\(unsafeRaw: Enum.allCases.map(\.rawValue).joined(separator: "',\n    '"))'
      )
    """)
  }

  func drop(enum Enum: (some PostgresEnum & RawRepresentable & CaseIterable).Type) async throws {
    try await self.execute("DROP TYPE \(unsafeRaw: Enum.typeName)")
  }
}
