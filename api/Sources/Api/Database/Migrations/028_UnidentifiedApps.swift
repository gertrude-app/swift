import FluentSQL
import Foundation
import Gertie

struct UnidentifiedApps: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.create(table: UnidentifiedApp.M28.self) {
      Column(.id, .uuid, .primaryKey)
      Column(UnidentifiedApp.M28.bundleId, .text, .unique)
      Column(UnidentifiedApp.M28.count, .int)
      Column(.createdAt, .timestampWithTimezone)
    }
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.drop(table: UnidentifiedApp.M28.self)
  }
}

extension UnidentifiedApp {
  enum M28: TableNamingMigration {
    static let tableName = "unidentified_apps"
    static let bundleId = FieldKey("bundle_id")
    static let count = FieldKey("count")
  }
}
