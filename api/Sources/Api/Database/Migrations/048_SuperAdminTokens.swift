import FluentSQL

struct SuperAdminTokens: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
    CREATE TABLE system.super_admin_tokens (
      id UUID PRIMARY KEY NOT NULL,
      value UUID NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
      deleted_at TIMESTAMPTZ NOT NULL
    );
    """)
    try await sql
      .execute("CREATE INDEX super_admin_tokens_value_idx ON system.super_admin_tokens(value);")
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP TABLE system.super_admin_tokens;")
  }
}
