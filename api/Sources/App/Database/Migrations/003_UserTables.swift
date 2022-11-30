import FluentSQL

struct UserTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await upUsers(sql)
    try await upDevices(sql)
    try await upUserTokens(sql)
    try await upUserKeychain(sql)
  }

  func down(sql: SQLDatabase) async throws {
    try await downUserKeychain(sql)
    try await downUserTokens(sql)
    try await downDevices(sql)
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
    try await sql.create(table: User.M3.self) {
      Column(.id, .uuid, .primaryKey)
      Column(User.M3.name, .text)
      Column(User.M3.keyloggingEnabled, .boolean)
      Column(User.M3.screenshotsEnabled, .boolean)
      Column(User.M3.screenshotsResolution, .bigint)
      Column(User.M3.screenshotsFrequency, .bigint)
      Column(User.M3.adminId, .uuid)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
      Column(.deletedAt, .timestampWithTimezone, .nullable)
    }
    try await sql.add(constraint: usersFk)
  }

  func downUsers(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: usersFk)
    try await sql.drop(table: User.M3.self)
  }

  // table: devices

  let devicesFk = Constraint.foreignKey(
    from: Device.M3.self,
    to: User.M3.self,
    thru: Device.M3.userId,
    onDelete: .cascade
  )

  func upDevices(_ sql: SQLDatabase) async throws {
    typealias M = Device.M3
    try await sql.create(table: M.self) {
      Column(.id, .uuid, .primaryKey)
      Column(M.userId, .uuid)
      Column(M.appVersion, .text, default: .text("0.0.0"))
      Column(M.serialNumber, .text)
      Column(M.modelIdentifier, .text)
      Column(M.customName, .text, .nullable)
      Column(M.hostname, .text, .nullable)
      Column(M.username, .text)
      Column(M.fullUsername, .text)
      Column(M.numericId, .bigint)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: .unique(M.self, [M.numericId, M.serialNumber]))
    try await sql.add(constraint: devicesFk)
  }

  func downDevices(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: devicesFk)
    try await sql.drop(table: Device.M3.self)
  }

  // table: user_tokens

  let userTokensUserFk = Constraint.foreignKey(
    from: UserToken.M3.self,
    to: User.M3.self,
    thru: UserToken.M3.userId,
    onDelete: .cascade
  )

  let userTokensDeviceFk = Constraint.foreignKey(
    from: UserToken.M3.self,
    to: Device.M3.self,
    thru: UserToken.M3.deviceId,
    onDelete: .cascade
  )

  func upUserTokens(_ sql: SQLDatabase) async throws {
    try await sql.create(table: UserToken.M3.self) {
      Column(.id, .uuid, .primaryKey)
      Column(UserToken.M3.value, .uuid, .unique)
      Column(UserToken.M3.userId, .uuid)
      Column(UserToken.M3.deviceId, .uuid, .nullable)
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
      Column(.deletedAt, .timestampWithTimezone, .nullable)
    }
    try await sql.add(constraint: userTokensUserFk)
    try await sql.add(constraint: userTokensDeviceFk)
  }

  func downUserTokens(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: userTokensUserFk)
    try await sql.drop(constraint: userTokensDeviceFk)
    try await sql.drop(table: UserToken.M3.self)
  }

  // table: user_keychain

  let userKeychainUserFk = Constraint.foreignKey(
    from: UserKeychain.M3.self,
    to: User.M3.self,
    thru: UserKeychain.M3.userId,
    onDelete: .cascade
  )

  let userKeychainKeychainFk = Constraint.foreignKey(
    from: UserKeychain.M3.self,
    to: Keychain.M2.self,
    thru: UserKeychain.M3.keychainId,
    onDelete: .cascade
  )

  func upUserKeychain(_ sql: SQLDatabase) async throws {
    typealias M = UserKeychain.M3
    try await sql.create(table: M.self) {
      Column(.id, .uuid, .primaryKey)
      Column(M.userId, .uuid)
      Column(M.keychainId, .uuid)
      Column(.createdAt, .timestampWithTimezone)
    }
    try await sql.add(constraint: .unique(M.self, [M.userId, M.keychainId]))
    try await sql.add(constraint: userKeychainUserFk)
    try await sql.add(constraint: userKeychainKeychainFk)
  }

  func downUserKeychain(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: userKeychainKeychainFk)
    try await sql.drop(constraint: userKeychainUserFk)
    try await sql.drop(table: UserKeychain.M3.self)
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

extension Device {
  enum M3: TableNamingMigration {
    static let tableName = "devices"
    static let userId = FieldKey("user_id")
    static let customName = FieldKey("custom_name")
    static let hostname = FieldKey("hostname")
    static let username = FieldKey("username")
    static let fullUsername = FieldKey("full_username")
    static let numericId = FieldKey("numeric_id")
    static let serialNumber = FieldKey("serial_number")
    static let appVersion = FieldKey("app_version")
    static let modelIdentifier = FieldKey("model_identifier")
  }
}

extension UserToken {
  enum M3: TableNamingMigration {
    static let tableName = "user_tokens"
    static let value = FieldKey("value")
    static let userId = FieldKey("user_id")
    static let deviceId = FieldKey("device_id")
  }
}

extension UserKeychain {
  enum M3: TableNamingMigration {
    static let tableName = "user_keychain"
    static let userId = FieldKey("user_id")
    static let keychainId = FieldKey("keychain_id")
  }
}
