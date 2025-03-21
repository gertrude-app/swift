import FluentSQL

enum Constraint {
  enum OnDelete {
    case cascade
    case noAction
    case setNull

    var sql: String {
      switch self {
      case .cascade:
        "CASCADE"
      case .noAction:
        "NO ACTION"
      case .setNull:
        "SET NULL"
      }
    }
  }

  case notNull(TableNamingMigration.Type, FieldKey)
  case unique(TableNamingMigration.Type, Set<FieldKey>)
  case primaryKey(TableNamingMigration.Type, Set<FieldKey>)
  case foreignKey(
    from: TableNamingMigration.Type,
    to: TableNamingMigration.Type,
    thru: FieldKey,
    onDelete: OnDelete
  )

  static func primaryKey(_ table: TableNamingMigration.Type, _ column: FieldKey) -> Self {
    .primaryKey(table, [column])
  }

  static func primaryKeyId(_ table: TableNamingMigration.Type) -> Self {
    .primaryKey(table, [.id])
  }

  static func unique(_ table: TableNamingMigration.Type, _ column: FieldKey) -> Self {
    .unique(table, [column])
  }

  var name: String {
    switch self {
    case .unique(let Migration, let columns):
      return invariant("uq:\(Migration.tableName).\(columns.psv)")
    case .primaryKey(let Migration, _):
      return invariant("pk:\(Migration.tableName)")
    case .foreignKey(let Table, _, let column, _):
      return invariant("fk:\(Table.tableName).\(column.description)")
    default:
      assertionFailure("Constraint \(self) has no name")
      return ""
    }
  }

  var addSql: SQLQueryString {
    switch self {
    case .notNull(let Migration, let column):
      """
        ALTER TABLE \(table: Migration.self)
        ALTER COLUMN \(col: column) SET NOT NULL
      """
    case .unique(let Migration, let columns):
      """
        ALTER TABLE \(table: Migration)
        ADD CONSTRAINT \(constraint: self) UNIQUE (\(unsafeRaw: columns.csv))
      """
    case .primaryKey(let Migration, let columns):
      """
        ALTER TABLE \(table: Migration)
        ADD CONSTRAINT \(constraint: self) PRIMARY KEY (\(unsafeRaw: columns.csv))
      """
    case .foreignKey(let Table, let ReferencedTable, let column, let onDelete):
      """
        ALTER TABLE \(table: Table)
        ADD CONSTRAINT \(constraint: self)
          FOREIGN KEY (\(col: column))
          REFERENCES \(table: ReferencedTable) (\(col: .id))
          ON DELETE \(unsafeRaw: onDelete.sql)
      """
    }
  }

  var dropSql: SQLQueryString {
    switch self {
    case .notNull(let Migration, let column):
      """
        ALTER TABLE \(table: Migration.self)
        ALTER COLUMN \(col: column) DROP NOT NULL
      """
    case .unique(let Migration, _),
         .foreignKey(let Migration, _, _, _),
         .primaryKey(let Migration, _):
      """
        ALTER TABLE \(table: Migration)
        DROP CONSTRAINT \(constraint: self)
      """
    }
  }
}

// helpers

private func invariant(_ ident: String) -> String {
  if ident.count > 63 {
    fatalError("constraint name `\(ident)` exceeds pg max identifier length")
  }
  return ident
}

private extension Set<FieldKey> {
  var psv: String {
    map(\.description).sorted().joined(separator: "+")
  }

  var csv: String {
    map(\.description).joined(separator: ", ")
  }
}
