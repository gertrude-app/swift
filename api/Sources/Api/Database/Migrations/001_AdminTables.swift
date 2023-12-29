import DuetSQL
import FluentSQL

struct AdminTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await upAdmins(sql)
    try await upAdminTokens(sql)
    try await upAdminVerifiedNotificationMethods(sql)
    try await upAdminNotifications(sql)
    try await upWaitlistedAdmins(sql)
  }

  func down(sql: SQLDatabase) async throws {
    try await downWaitlistedAdmins(sql)
    try await downAdminNotifications(sql)
    try await downAdminVerifiedNotificationMethods(sql)
    try await downAdminTokens(sql)
    try await downAdmins(sql)
  }

  // table: admins

  func upAdmins(_ sql: SQLDatabase) async throws {
    try await sql.create(enum: Admin.M1.Deleted.SubscriptionStatus.self)
    try await sql.create(table: Admin.M1.self) {
      Column(.id, .uuid, .primaryKey)
      Column(Admin.M1.email, .text, .unique)
      Column(Admin.M1.password, .text)
      Column(Admin.M1.subscriptionId, .text, .nullable)
      Column(
        Admin.M1.subscriptionStatus,
        .enum(Admin.M1.Deleted.SubscriptionStatus.self),
        default: .enumValue(Admin.M1.Deleted.SubscriptionStatus.pendingEmailVerification)
      )
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
      Column(.deletedAt, .timestampWithTimezone, .nullable)
    }
  }

  func downAdmins(_ sql: SQLDatabase) async throws {
    try await sql.drop(table: Admin.M1.self)
    try await sql.drop(enum: Admin.SubscriptionStatus.self)
  }

  // table: admin_tokens

  let adminTokensFk = Constraint.foreignKey(
    from: AdminToken.M1.self,
    to: Admin.M1.self,
    thru: AdminToken.M1.adminId,
    onDelete: .cascade
  )

  func upAdminTokens(_ sql: SQLDatabase) async throws {
    try await sql.create(table: AdminToken.M1.self) {
      Column(.id, .uuid, .primaryKey)
      Column(AdminToken.M1.value, .uuid)
      Column(AdminToken.M1.adminId, .uuid)
      Column(.createdAt, .timestampWithTimezone)
      Column(.deletedAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: adminTokensFk)
  }

  func downAdminTokens(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: adminTokensFk)
    try await sql.drop(table: AdminToken.M1.self)
  }

  // table: admin_verified_notification_methods

  let adminVerifiedNotificationMethodsFk = Constraint.foreignKey(
    from: AdminVerifiedNotificationMethod.M1.self,
    to: Admin.M1.self,
    thru: AdminVerifiedNotificationMethod.M1.adminId,
    onDelete: .cascade
  )

  func upAdminVerifiedNotificationMethods(_ sql: SQLDatabase) async throws {
    typealias M = AdminVerifiedNotificationMethod.M1
    try await sql.create(table: M.self) {
      Column(.id, .uuid, .primaryKey)
      Column(M.adminId, .uuid)
      Column(M.config, .jsonb)
      Column(.createdAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: adminVerifiedNotificationMethodsFk)
    try await sql.add(constraint: .unique(M.self, [M.adminId, M.config]))
  }

  func downAdminVerifiedNotificationMethods(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: adminVerifiedNotificationMethodsFk)
    try await sql.drop(table: AdminVerifiedNotificationMethod.M1.self)
  }

  // table: admin_notifications

  let adminNotificationsAdminIdFk = Constraint.foreignKey(
    from: AdminNotification.M1.self,
    to: Admin.M1.self,
    thru: AdminNotification.M1.adminId,
    onDelete: .cascade
  )

  let adminNotificationsMethodIdFk = Constraint.foreignKey(
    from: AdminNotification.M1.self,
    to: AdminVerifiedNotificationMethod.M1.self,
    thru: AdminNotification.M1.methodId,
    onDelete: .cascade
  )

  func upAdminNotifications(_ sql: SQLDatabase) async throws {
    typealias M = AdminNotification.M1
    try await sql.create(enum: AdminNotification.Trigger.self)
    try await sql.create(table: M.self) {
      Column(.id, .uuid, .primaryKey)
      Column(M.trigger, .enum(AdminNotification.Trigger.self))
      Column(M.adminId, .uuid)
      Column(M.methodId, .uuid)
      Column(.createdAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: adminNotificationsAdminIdFk)
    try await sql.add(constraint: adminNotificationsMethodIdFk)
    try await sql.add(constraint: .unique(M.self, [M.methodId, M.adminId, M.trigger]))
  }

  func downAdminNotifications(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: adminNotificationsAdminIdFk)
    try await sql.drop(constraint: adminNotificationsMethodIdFk)
    try await sql.drop(table: AdminNotification.M1.self)
    try await sql.drop(enum: AdminNotification.Trigger.self)
  }

  // table: waitlisted_admins

  func upWaitlistedAdmins(_ sql: SQLDatabase) async throws {
    try await sql.create(table: WaitlistedAdmin.M1.self) {
      Column(.id, .uuid, .primaryKey)
      Column(WaitlistedAdmin.M1.email, .text, .unique)
      Column(WaitlistedAdmin.M1.signupToken, .uuid, [.nullable, .unique])
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }
  }

  func downWaitlistedAdmins(_ sql: SQLDatabase) async throws {
    try await sql.drop(table: WaitlistedAdmin.M1.self)
  }
}

// migration extensions

extension Admin {
  enum M1: TableNamingMigration {
    static let tableName = "admins"
    static let email = FieldKey("email")
    static let password = FieldKey("password")
    static let subscriptionId = FieldKey("subscription_id")
    static let subscriptionStatus = FieldKey("subscription_status")
    static let subscriptionStatusTypeName = "enum_admin_subscription_status"

    enum Deleted {
      enum SubscriptionStatus: String, Codable, CaseIterable, PostgresEnum {
        var typeName: String { Admin.M1.subscriptionStatusTypeName }
        case pendingEmailVerification
        case emailVerified
        case signupCanceled
        case complimentary
        case incomplete
        case incompleteExpired
        case trialing
        case active
        case pastDue
        case canceled
        case unpaid
      }
    }
  }
}

extension AdminToken {
  enum M1: TableNamingMigration {
    static let tableName = "admin_tokens"
    static let value = FieldKey("value")
    static let adminId = FieldKey("admin_id")
  }
}

extension AdminNotification {
  enum M1: TableNamingMigration {
    static let tableName = "admin_notifications"
    static let trigger = FieldKey("trigger")
    static let adminId = FieldKey("admin_id")
    static let methodId = FieldKey("method_id")
    static let triggerTypeName = "enum_admin_notification_trigger"
  }
}

extension AdminVerifiedNotificationMethod {
  enum M1: TableNamingMigration {
    static let tableName = "admin_verified_notification_methods"
    static let adminId = FieldKey("admin_id")
    static let config = FieldKey("config")
  }
}

// used to be a model, converted to enum/namespace for migration history
enum WaitlistedAdmin {
  enum M1: TableNamingMigration {
    static let tableName = "waitlisted_admins"
    static let email = FieldKey("email")
    static let signupToken = FieldKey("signup_token")
  }
}
