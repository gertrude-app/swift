import FluentSQL

struct AdminTables: GertieMigration {
  func prepare(sql: SQLDatabase) async throws {}

  func revert(sql: SQLDatabase) async throws {}
}
