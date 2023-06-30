import FluentSQL
import XCore

struct UnexpectedErrorTable: GertieMigration {
  let deviceIdFk = Constraint.foreignKey(
    from: UnexpectedError.M8.self,
    to: Device.M3.self,
    thru: UnexpectedError.M8.deviceId,
    onDelete: .setNull
  )

  let adminIdFk = Constraint.foreignKey(
    from: UnexpectedError.M8.self,
    to: Admin.M1.self,
    thru: UnexpectedError.M8.adminId,
    onDelete: .setNull
  )

  func up(sql: SQLDatabase) async throws {
    try await sql.create(table: UnexpectedError.M8.self) {
      Column(.id, .uuid, .primaryKey)
      Column(UnexpectedError.M8.errorId, .text)
      Column(UnexpectedError.M8.context, .text)
      Column(UnexpectedError.M8.deviceId, .uuid, .nullable)
      Column(UnexpectedError.M8.adminId, .uuid, .nullable)
      Column(UnexpectedError.M8.detail, .text, .nullable)
      Column(.createdAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: deviceIdFk)
    try await sql.add(constraint: adminIdFk)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.drop(constraint: deviceIdFk)
    try await sql.drop(constraint: adminIdFk)
    try await sql.drop(table: UnexpectedError.M8.self)
  }
}

// extensions

extension UnexpectedError {
  enum M8: TableNamingMigration {
    static let tableName = "unexpected_errors"
    static let context = FieldKey("context")
    static let errorId = FieldKey("error_id")
    static let deviceId = FieldKey("device_id")
    static let adminId = FieldKey("admin_id")
    static let detail = FieldKey("detail")
  }
}
