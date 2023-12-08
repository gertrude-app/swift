import FluentSQL
import Foundation
import Gertie

struct ReworkPayments: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    let admins = try await getAdmins(sql)
    try await sql.dropColumn(Admin.M1.subscriptionStatus, on: Admin.M1.self)
    try await sql.drop(enum: Admin.M1.LegacySubscriptionStatus.self)
    try await sql.create(enum: Admin.SubscriptionStatus.self)
    try await sql.dropColumn(.deletedAt, on: Admin.M1.self)

    try await sql.addColumn(
      Admin.M1.subscriptionStatus,
      on: Admin.M1.self,
      type: .enum(Admin.SubscriptionStatus.self),
      default: .enumValue(Admin.SubscriptionStatus.unpaid) // <-- temp
    )

    try await sql.addColumn(
      Admin.M16.subscriptionStatusExpiration,
      on: Admin.M1.self,
      type: .timestampWithTimezone,
      nullable: true
    )

    let updates: [(UUID, Admin.SubscriptionStatus, Date)] = admins.map { admin in
      switch admin.subscriptionStatus {
      case "pendingEmailVerification":
        return (admin.id, .pendingEmailVerification, admin.createdAt.advanced(by: .days(7)))
      case "canceled":
        return (admin.id, .unpaid, Current.date().advanced(by: .days(365)))
      case "complimentary":
        return (admin.id, .complimentary, .distantFuture)
      case "trialing", "emailVerified":
        return (admin.id, .trialing, admin.createdAt.advanced(by: .days(60 - 7)))
      default:
        if Env.mode == .prod {
          fatalError("unexpected subscription status: `\(admin.subscriptionStatus)`")
        } else {
          return (admin.id, .complimentary, .distantFuture)
        }
      }
    }

    for (id, status, date) in updates {
      try await sql.execute("""
        UPDATE \(table: Admin.M1.self)
        SET
          \(col: Admin.M1.subscriptionStatus) = '\(raw: status.rawValue)',
          \(col: Admin.M16.subscriptionStatusExpiration) = '\(raw: date.postgresTimestampString)'
        WHERE \(col: .id) = '\(uuid: id)'
      """)
    }

    try await sql.dropDefault(from: Admin.M1.subscriptionStatus, on: Admin.M1.self)

    try await sql.create(table: DeletedEntity.M16.self) {
      Column(.id, .uuid, .primaryKey)
      Column(DeletedEntity.M16.type, .text)
      Column(DeletedEntity.M16.reason, .text)
      Column(DeletedEntity.M16.data, .text)
      Column(.createdAt, .timestampWithTimezone)
    }
  }

  func down(sql: SQLDatabase) async throws {
    let admins = try await getAdmins(sql)

    try await sql.dropColumn(Admin.M1.subscriptionStatus, on: Admin.M1.self)
    try await sql.drop(enum: Admin.SubscriptionStatus.self)
    try await sql.create(enum: Admin.M1.LegacySubscriptionStatus.self)

    try await sql.addColumn(
      .deletedAt,
      on: Admin.M1.self,
      type: .timestampWithTimezone,
      nullable: true
    )

    try await sql.addColumn(
      Admin.M1.subscriptionStatus,
      on: Admin.M1.self,
      type: .enum(Admin.M1.LegacySubscriptionStatus.self),
      default: .enumValue(Admin.M1.LegacySubscriptionStatus.pendingEmailVerification) // <-- temp
    )

    try await sql.dropColumn(Admin.M16.subscriptionStatusExpiration, on: Admin.M1.self)

    let updates: [(UUID, Admin.M1.LegacySubscriptionStatus)] = admins.map { admin in
      switch admin.subscriptionStatus {
      case Admin.SubscriptionStatus.pendingEmailVerification.rawValue:
        return (admin.id, .pendingEmailVerification)
      case Admin.SubscriptionStatus.trialing.rawValue,
           Admin.SubscriptionStatus.trialExpiringSoon.rawValue:
        return (admin.id, .trialing)
      case Admin.SubscriptionStatus.overdue.rawValue:
        return (admin.id, .pastDue)
      case Admin.SubscriptionStatus.paid.rawValue:
        return (admin.id, .active)
      case Admin.SubscriptionStatus.unpaid.rawValue:
        return (admin.id, .canceled)
      case Admin.SubscriptionStatus.complimentary.rawValue:
        return (admin.id, .complimentary)
      case Admin.SubscriptionStatus.pendingAccountDeletion.rawValue:
        return (admin.id, .canceled)
      default:
        fatalError("unexpected subscription status: `\(admin.subscriptionStatus)`")
      }
    }

    for (id, status) in updates {
      try await sql.execute("""
        UPDATE \(table: Admin.M1.self)
        SET \(col: Admin.M1.subscriptionStatus) = '\(raw: status.rawValue)'
        WHERE \(col: .id) = '\(uuid: id)'
      """)
    }

    try await sql.drop(table: DeletedEntity.M16.self)
  }

  private func getAdmins(_ sql: SQLDatabase) async throws -> [MigrationAdmin] {
    let adminRows = try await sql.execute("""
      SELECT
        \(col: .id),
        \(col: Admin.M1.subscriptionStatus),
        \(col: .createdAt)
      FROM admins
    """)

    return try adminRows.map { try $0.decode(
      model: MigrationAdmin.self,
      prefix: nil,
      keyDecodingStrategy: .convertFromSnakeCase
    ) }
  }
}

private struct MigrationAdmin: Codable {
  let id: UUID
  let subscriptionStatus: String
  let createdAt: Date
}

extension Admin {
  enum M16 {
    static let subscriptionStatusExpiration = FieldKey("subscription_status_expiration")
  }
}

extension DeletedEntity {
  enum M16: TableNamingMigration {
    static let tableName = "deleted_entities"
    static let type = FieldKey("type")
    static let reason = FieldKey("reason")
    static let data = FieldKey("data")
  }
}
