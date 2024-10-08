import FluentSQL
import Foundation
import Gertie

struct ScreenshotDisplayId: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      Screenshot.M27.displayId,
      on: Screenshot.M4.self,
      type: .int,
      nullable: true
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(
      Screenshot.M27.displayId,
      on: Screenshot.M4.self
    )
  }
}

struct RevertScreenshotDisplayId: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await ScreenshotDisplayId().down(sql: sql)
  }

  func down(sql: SQLDatabase) async throws {
    try await ScreenshotDisplayId().up(sql: sql)
  }
}

extension Screenshot {
  enum M27 {
    static let displayId = FieldKey("display_id")
  }
}
