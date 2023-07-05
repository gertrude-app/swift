import FluentSQL
import XCore

struct InterestingEventsTable: GertieMigration {
  let deviceIdFk = Constraint.foreignKey(
    from: InterestingEvent.M8.self,
    to: Device.M3.self,
    thru: InterestingEvent.M8.deviceId,
    onDelete: .setNull
  )

  let adminIdFk = Constraint.foreignKey(
    from: InterestingEvent.M8.self,
    to: Admin.M1.self,
    thru: InterestingEvent.M8.adminId,
    onDelete: .setNull
  )

  func up(sql: SQLDatabase) async throws {
    try await sql.create(table: InterestingEvent.M8.self) {
      Column(.id, .uuid, .primaryKey)
      Column(InterestingEvent.M8.eventId, .text)
      Column(InterestingEvent.M8.kind, .text)
      Column(InterestingEvent.M8.context, .text)
      Column(InterestingEvent.M8.deviceId, .uuid, .nullable)
      Column(InterestingEvent.M8.adminId, .uuid, .nullable)
      Column(InterestingEvent.M8.detail, .text, .nullable)
      Column(.createdAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: deviceIdFk)
    try await sql.add(constraint: adminIdFk)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.drop(constraint: deviceIdFk)
    try await sql.drop(constraint: adminIdFk)
    try await sql.drop(table: InterestingEvent.M8.self)
  }
}

// extensions

extension InterestingEvent {
  enum M8: TableNamingMigration {
    static let tableName = "interesting_events"
    static let eventId = FieldKey("event_id")
    static let kind = FieldKey("kind")
    static let context = FieldKey("context")
    static let deviceId = FieldKey("device_id")
    static let adminId = FieldKey("admin_id")
    static let detail = FieldKey("detail")
  }
}
