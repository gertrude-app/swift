import FluentSQL

struct ActivityTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await upScreenshots(sql)
    try await upKeystrokeLines(sql)
  }

  func down(sql: SQLDatabase) async throws {
    try await downKeystrokeLines(sql)
    try await downScreenshots(sql)
  }

  // table: screenshots

  let screenshotsFk = Constraint.foreignKey(
    from: Screenshot.M4.self,
    to: Device.M3.self,
    thru: Screenshot.M4.deviceId,
    onDelete: .cascade
  )

  func upScreenshots(_ sql: SQLDatabase) async throws {
    try await sql.create(table: Screenshot.M4.self) {
      Column(.id, .uuid, .primaryKey)
      Column(Screenshot.M4.deviceId, .uuid)
      Column(Screenshot.M4.url, .text)
      Column(Screenshot.M4.width, .bigint)
      Column(Screenshot.M4.height, .bigint)
      Column(.createdAt, .timestampWithTimezone)
      Column(.deletedAt, .timestampWithTimezone, .nullable)
    }
    try await sql.add(constraint: screenshotsFk)
  }

  func downScreenshots(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: screenshotsFk)
    try await sql.drop(table: Screenshot.M4.self)
  }

  // table: keystroke_lines

  let keystrokeLinesFk = Constraint.foreignKey(
    from: KeystrokeLine.M4.self,
    to: Device.M3.self,
    thru: KeystrokeLine.M4.deviceId,
    onDelete: .cascade
  )

  func upKeystrokeLines(_ sql: SQLDatabase) async throws {
    try await sql.create(table: KeystrokeLine.M4.self) {
      Column(.id, .uuid, .primaryKey)
      Column(KeystrokeLine.M4.deviceId, .uuid)
      Column(KeystrokeLine.M4.appName, .text)
      Column(KeystrokeLine.M4.line, .text)
      Column(.createdAt, .timestampWithTimezone)
      Column(.deletedAt, .timestampWithTimezone, .nullable)
    }
    try await sql.add(constraint: keystrokeLinesFk)
  }

  func downKeystrokeLines(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: keystrokeLinesFk)
    try await sql.drop(table: KeystrokeLine.M4.self)
  }
}

// migration extensions

extension Screenshot {
  struct M4: TableNamingMigration {
    static let tableName = "screenshots"
    static let deviceId = FieldKey("device_id")
    static let url = FieldKey("url")
    static let width = FieldKey("width")
    static let height = FieldKey("height")
  }
}

extension KeystrokeLine {
  struct M4: TableNamingMigration {
    static let tableName = "keystroke_lines"
    static let deviceId = FieldKey("device_id")
    static let appName = FieldKey("app_name")
    static let line = FieldKey("line")
  }
}
