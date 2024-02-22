import FluentSQL
import Gertie

struct BrowsersTable: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.create(table: Browser.M20.self) {
      Column(.id, .uuid, .primaryKey)
      Column(Browser.M20.match, .jsonb, .unique)
      Column(.createdAt, .timestampWithTimezone)
    }
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.drop(table: Browser.M20.self)
  }
}

extension Browser {
  enum M20: TableNamingMigration {
    static let tableName = "browsers"
    static let match = FieldKey("match")
  }
}
