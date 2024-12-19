import FluentSQL
import Foundation
import Gertie

struct IOSBlockRules: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.create(table: IOSBlockRule.M31.self) {
      Column(.id, .uuid, .primaryKey)
      Column(IOSBlockRule.M31.vendorId, .uuid, .nullable)
      Column(IOSBlockRule.M31.rule, .jsonb)
      Column(IOSBlockRule.M31.group, .text, .nullable)
      Column(IOSBlockRule.M31.comment, .text, .nullable)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }
    try await sql.createIndex(on: IOSBlockRule.M31.self, IOSBlockRule.M31.vendorId)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.drop(table: IOSBlockRule.M31.self)
  }
}

extension IOSBlockRule {
  enum M31: TableNamingMigration {
    static let tableName = "ios_block_rules"
    static let id = FieldKey("id")
    static let vendorId = FieldKey("vendor_id")
    static let rule = FieldKey("rule")
    static let group = FieldKey("group")
    static let comment = FieldKey("comment")
    static let createdAt = FieldKey("created_at")
    static let updatedAt = FieldKey("updated_at")
  }
}
