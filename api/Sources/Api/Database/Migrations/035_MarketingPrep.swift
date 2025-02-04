import FluentSQL
import Foundation

struct MarketingPrep: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN monthly_price INT
      NOT NULL DEFAULT 1500;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      ADD COLUMN trial_period_days INT
      NOT NULL DEFAULT 21;
    """)

    try await sql.execute("""
      UPDATE parent.parents
      SET
        monthly_price = 500,
        trial_period_days = 60;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN trial_period_days;
    """)

    try await sql.execute("""
      ALTER TABLE parent.parents
      DROP COLUMN monthly_price;
    """)
  }
}
