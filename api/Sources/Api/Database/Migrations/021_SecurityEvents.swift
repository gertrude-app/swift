import DuetSQL
import FluentSQL
import Gertie

struct SecurityEvents: GertieMigration {
  let securityEventFk = Constraint.foreignKey(
    from: SecurityEvent.M21.self,
    to: UserDevice.M11.self,
    thru: SecurityEvent.M21.userDeviceId,
    onDelete: .cascade
  )

  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      UserDevice.M21.isAdmin,
      on: UserDevice.M11.self,
      type: .boolean,
      nullable: true
    )
    try await sql.addColumn(
      Device.M21.osVersion,
      on: Device.M3.self,
      type: .varchar(12),
      nullable: true
    )
    try await sql.create(table: SecurityEvent.M21.self) {
      Column(.id, .uuid, .primaryKey)
      Column(SecurityEvent.M21.adminId, .uuid)
      Column(SecurityEvent.M21.userDeviceId, .uuid, .nullable)
      Column(SecurityEvent.M21.event, .varchar(255))
      Column(SecurityEvent.M21.detail, .text, .nullable)
      Column(.createdAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: self.securityEventFk)

    // add new enum case
    try await sql.execute("""
      ALTER TYPE \(raw: AdminNotification.Trigger.typeName)
      ADD VALUE '\(raw: AdminNotification.Trigger.adminChildSecurityEvent.rawValue)'
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(UserDevice.M21.isAdmin, on: UserDevice.M11.self)
    try await sql.dropColumn(Device.M21.osVersion, on: Device.M3.self)
    try await sql.drop(constraint: self.securityEventFk)
    try await sql.drop(table: SecurityEvent.M21.self)

    try await AdminNotification.query()
      .where(.trigger == .enum(AdminNotification.Trigger.adminChildSecurityEvent))
      .delete()

    try await self.dropEnumCase(sql)
  }

  func dropEnumCase(_ sql: SQLDatabase) async throws {
    // 1) switch the column to text temporarily
    try await sql.execute("""
      ALTER TABLE \(table: AdminNotification.M1.self)
      ALTER COLUMN \(col: AdminNotification.M1.trigger)
      TYPE text
    """)

    // 2) drop the enum
    try await sql.drop(enum: AdminNotification.Trigger.self)

    // 3) recreate old enum
    try await sql.create(enum: AdminNotification.M1.Trigger.self)

    // 4) switch the column back to the enum
    try await sql.execute("""
      ALTER TABLE \(table: AdminNotification.M1.self)
      ALTER COLUMN \(col: AdminNotification.M1.trigger)
      TYPE \(raw: AdminNotification.Trigger.typeName)
      USING \(col: AdminNotification.M1.trigger)::\(raw: AdminNotification.Trigger.typeName)
    """)
  }
}

extension UserDevice {
  enum M21 {
    static let isAdmin = FieldKey("is_admin")
  }
}

extension Device {
  enum M21 {
    static let osVersion = FieldKey("os_version")
  }
}

extension SecurityEvent {
  enum M21: TableNamingMigration {
    static let tableName = "security_events"
    static let adminId = FieldKey("admin_id")
    static let userDeviceId = FieldKey("user_device_id")
    static let event = FieldKey("event")
    static let detail = FieldKey("detail")
  }
}
