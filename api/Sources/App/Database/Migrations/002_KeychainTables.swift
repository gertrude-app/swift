import FluentSQL

struct KeychainTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await upKeychains(sql)
    try await upKeys(sql)
  }

  func down(sql: SQLDatabase) async throws {
    try await downKeys(sql)
    try await downKeychains(sql)
  }

  // table: keychains

  let keychainsFk = Constraint.foreignKey(
    from: Keychain.M2.self,
    to: Admin.M1.self,
    thru: Keychain.M2.authorId,
    onDelete: .cascade
  )

  func upKeychains(_ sql: SQLDatabase) async throws {
    try await sql.create(
      table: Keychain.M2.self,
      Column(.id, .uuid, .primaryKey),
      Column(Keychain.M2.name, .text),
      Column(Keychain.M2.description, .text, .nullable),
      Column(Keychain.M2.isPublic, .boolean),
      Column(Keychain.M2.authorId, .uuid),
      Column(.createdAt, .timestampWithTimezone),
      Column(.updatedAt, .timestampWithTimezone),
      Column(.deletedAt, .timestampWithTimezone, .nullable)
    )
    try await sql.add(constraint: keychainsFk)
  }

  func downKeychains(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: keychainsFk)
    try await sql.drop(table: Keychain.M2.self)
  }

  // table: keys

  let keysFk = Constraint.foreignKey(
    from: Key.M2.self,
    to: Keychain.M2.self,
    thru: Key.M2.keychainId,
    onDelete: .cascade
  )

  func upKeys(_ sql: SQLDatabase) async throws {
    try await sql.create(
      table: Key.M2.self,
      Column(.id, .uuid, .primaryKey),
      Column(Key.M2.key, .jsonb),
      Column(Key.M2.comment, .text),
      Column(Key.M2.keychainId, .uuid),
      Column(.createdAt, .timestampWithTimezone),
      Column(.updatedAt, .timestampWithTimezone),
      Column(.deletedAt, .timestampWithTimezone, .nullable)
    )
    try await sql.add(constraint: keysFk)
  }

  func downKeys(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: keysFk)
    try await sql.drop(table: Key.M2.self)
  }
}

// migration extensions

extension Keychain {
  enum M2: TableNamingMigration {
    static let tableName = "keychains"
    static let authorId = FieldKey("author_id")
    static let name = FieldKey("name")
    static let description = FieldKey("description")
    static let isPublic = FieldKey("is_public")
  }
}

extension Key {
  enum M2: TableNamingMigration {
    static let tableName = "keys"
    static let key = FieldKey("key")
    static let comment = FieldKey("comment")
    static let keychainId = FieldKey("keychain_id")
  }
}
