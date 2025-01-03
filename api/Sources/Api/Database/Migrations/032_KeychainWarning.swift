import FluentSQL

struct KeychainWarning: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      Keychain.M32.warning,
      on: Keychain.M2.self,
      type: .text,
      nullable: true
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(
      Keychain.M32.warning,
      on: Keychain.M2.self
    )
  }
}

extension Keychain {
  enum M32 {
    static let warning = FieldKey("warning")
  }
}
