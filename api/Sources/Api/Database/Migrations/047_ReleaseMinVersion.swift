import FluentSQL

struct ReleaseMinVersion: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE macapp.releases
      ADD COLUMN min_version text NOT NULL DEFAULT '10.15';
    """)

    try await sql.execute("""
      ALTER TABLE macapp.releases
      ALTER COLUMN min_version DROP DEFAULT;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE macapp.releases
      DROP COLUMN min_version;
    """)
  }
}
