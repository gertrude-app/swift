import FluentSQL

struct UserTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await upUsers(sql)
  }

  func down(sql: SQLDatabase) async throws {
    try await downUsers(sql)
  }

  // table: users

  let usersFk = Constraint.foreignKey(
    from: User.M3.self,
    to: Admin.M1.self,
    thru: User.M3.adminId,
    onDelete: .cascade
  )

  func upUsers(_ sql: SQLDatabase) async throws {
    try await sql.create(
      table: User.M3.self,
      Column(.id, .uuid, .primaryKey),
      Column(User.M3.name, .text),
      Column(User.M3.keyloggingEnabled, .boolean),
      Column(User.M3.screenshotsEnabled, .boolean),
      Column(User.M3.screenshotsResolution, .bigint),
      Column(User.M3.screenshotsFrequency, .bigint),
      Column(User.M3.adminId, .uuid),
      Column(.createdAt, .timestampWithTimezone),
      Column(.updatedAt, .timestampWithTimezone),
      Column(.deletedAt, .timestampWithTimezone, .nullable)
    )
    try await sql.add(constraint: usersFk)
  }

  func downUsers(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: usersFk)
    try await sql.drop(table: User.M3.self)
  }
}

// migration extensions

extension User {
  enum M3: TableNamingMigration {
    static let tableName = "users"
    static let name = FieldKey("name")
    static let keyloggingEnabled = FieldKey("keylogging_enabled")
    static let screenshotsEnabled = FieldKey("screenshots_enabled")
    static let screenshotsResolution = FieldKey("screenshots_resolution")
    static let screenshotsFrequency = FieldKey("screenshots_frequency")
    static let adminId = FieldKey("admin_id")
  }
}
