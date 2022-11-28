import FluentSQL
import Rainbow
import Vapor

protocol GertieMigration: AsyncMigration {
  func prepare(sql: SQLDatabase) async throws
  func revert(sql: SQLDatabase) async throws
}

public enum MigrationDirection: String {
  case up
  case down
}

public protocol TableNamingMigration {
  static var tableName: String { get }
}

extension GertieMigration {
  func prepare(on database: Database) async throws {
    log(.up)
    try await prepare(sql: database as! SQLDatabase)
  }

  func revert(on database: Database) async throws {
    log(.down)
    try await revert(sql: database as! SQLDatabase)
  }

  func debugPause(seconds: Int = 20, _ message: String) async throws {
    // Current.logger.warning("PAUSING FOR \(seconds)s: \(message)")
    try await Task.sleep(seconds: seconds)
  }
}

public extension Migration {
  func log(_ direction: MigrationDirection) {
    // let dir = direction == .up ? "UP".green : "DOWN".yellow
    // Current.logger.info("Running migration: \(String(describing: Self.self).magenta) \(dir)")
  }

  func convertStringJsonColumnToJsonb(
    tableName: String,
    column: FieldKey,
    on db: Database
  ) async throws {
    let sql = db as! SQLDatabase
    _ = try await sql.raw(
      """
      ALTER TABLE "\(raw: tableName)"
      ALTER COLUMN "\(raw: column.description)" TYPE jsonb
      USING \(raw: column.description)::jsonb;
      """
    ).all()
  }

  func revertStringJsonColumnToJsonb(
    tableName: String,
    column: FieldKey,
    on db: Database
  ) async throws {
    let sql = db as! SQLDatabase
    _ = try await sql.raw(
      """
      ALTER TABLE "\(raw: tableName)"
      ALTER COLUMN "\(raw: column.description)" TYPE string;
      """
    ).all()
  }
}

public struct UniqueConstraint {
  public let table: TableNamingMigration.Type
  public let columns: Set<FieldKey>

  var name: String {
    "unique_\(columns.map(\.description).joined(separator: "_"))"
  }

  public init(table: TableNamingMigration.Type, columns: Set<FieldKey>) {
    self.table = table
    self.columns = columns
    if name.count > 63 {
      fatalError("unique constraint name exceeds pg max identifier length: `\(name)`")
    }
  }
}

public struct ForeignKey {
  public let table: TableNamingMigration.Type
  public let referencedTable: TableNamingMigration.Type
  public let column: FieldKey

  public var name: String {
    "fk_\(table.tableName.singular)_\(column.description)"
  }

  public init(
    from table: TableNamingMigration.Type,
    to referencedTable: TableNamingMigration.Type,
    thru column: FieldKey
  ) {
    self.table = table
    self.referencedTable = referencedTable
    self.column = column
    if name.count > 63 {
      fatalError("foreign key name exceeds pg max identifier length: `\(name)`")
    }
  }
}
