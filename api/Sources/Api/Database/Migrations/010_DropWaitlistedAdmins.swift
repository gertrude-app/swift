import FluentSQL
import XCore

struct DropWaitlistedAdmins: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await AdminTables().downWaitlistedAdmins(sql)
  }

  func down(sql: SQLDatabase) async throws {
    try await AdminTables().upWaitlistedAdmins(sql)
  }
}
