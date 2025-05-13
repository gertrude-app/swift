import FluentSQL
import Foundation

struct FlaggedActivity: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE macapp.screenshots
      ADD COLUMN flagged TIMESTAMPTZ;
    """)
    try await sql.execute("""
      ALTER TABLE macapp.keystroke_lines
      ADD COLUMN flagged TIMESTAMPTZ;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE macapp.screenshots
      DROP COLUMN flagged;
    """)
    try await sql.execute("""
      ALTER TABLE macapp.keystroke_lines
      DROP COLUMN flagged;
    """)
  }
}
