import Dependencies
import FluentSQL

struct RenameParentNotifMethods: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.verified_notification_methods
      RENAME TO notification_methods;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.notification_methods
      RENAME TO verified_notification_methods;
    """)
  }
}
