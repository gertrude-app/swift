import FluentSQL

struct AdminTables: GertieMigration {
  func prepare(sql: SQLDatabase) async throws {
    try await sql.create(enum: Admin.SubscriptionStatus.self)

    try await sql.create(
      table: Admin.M1.self,
      Column(Admin.M1.id, .uuid, .primaryKey),
      Column(Admin.M1.email, .text, .unique),
      Column(Admin.M1.password, .text),
      Column(Admin.M1.subscriptionId, .text, .nullable),
      Column(
        Admin.M1.subscriptionStatus,
        .enum(Admin.SubscriptionStatus.self),
        default: .enumValue(Admin.SubscriptionStatus.pendingEmailVerification)
      ),
      Column(.createdAt, .timestampWithTimezone),
      Column(.updatedAt, .timestampWithTimezone),
      Column(.deletedAt, .timestampWithTimezone, .nullable)
    )
  }

  func revert(sql: SQLDatabase) async throws {
    try await sql.drop(table: Admin.M1.self)
    try await sql.drop(enum: Admin.SubscriptionStatus.self)
  }
}

// migration extensions

extension Admin {
  enum M1: TableNamingMigration {
    static let tableName = "admins"
    static let id = FieldKey("id")
    static let email = FieldKey("email")
    static let password = FieldKey("password")
    static let subscriptionId = FieldKey("subscription_id")
    static let subscriptionStatus = FieldKey("subscription_status")
  }
}

/*

 CREATE TABLE admins (
     id uuid NOT NULL,
     email text NOT NULL,
     created_at timestamp with time zone NOT NULL,
     updated_at timestamp with time zone NOT NULL,
     deleted_at timestamp with time zone,
     subscription_id text,
     subscription_status admin_user_subscription_status DEFAULT 'pendingEmailVerification'::admin_user_subscription_status,
     password text NOT NULL
 );

 */
