import FluentSQL
import Rainbow
import Vapor

protocol GertieMigration: AsyncMigration {
  func up(sql: SQLDatabase) async throws
  func down(sql: SQLDatabase) async throws
}

enum MigrationDirection: String {
  case up
  case down
}

protocol TableNamingMigration {
  static var tableName: String { get }
}

extension GertieMigration {
  func prepare(on database: Database) async throws {
    try await up(sql: database as! SQLDatabase)
  }

  func revert(on database: Database) async throws {
    try await down(sql: database as! SQLDatabase)
  }

  func debugPause(seconds: Int = 20, _ message: String) async throws {
    Current.logger.warning("PAUSING FOR \(seconds)s: \(message)")
    try await Task.sleep(seconds: seconds)
  }
}

extension Migration {
  func log(_ direction: MigrationDirection) {
    let dir = direction == .up ? "UP".green : "DOWN".yellow
    Current.logger.info("Running migration: \(String(describing: Self.self).magenta) \(dir)")
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
