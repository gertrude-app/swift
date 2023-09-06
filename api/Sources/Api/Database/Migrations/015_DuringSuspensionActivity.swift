import FluentSQL

struct DuringSuspensionActivity: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      Screenshot.M15.filterSuspended,
      on: Screenshot.M4.self,
      type: .boolean,
      default: .boolean(false)
    )
    try await sql.addColumn(
      KeystrokeLine.M15.filterSuspended,
      on: KeystrokeLine.M4.self,
      type: .boolean,
      default: .boolean(false)
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(Screenshot.M15.filterSuspended, on: Screenshot.M4.self)
    try await sql.dropColumn(KeystrokeLine.M15.filterSuspended, on: KeystrokeLine.M4.self)
  }
}

extension Screenshot {
  enum M15 {
    static let filterSuspended = FieldKey("filter_suspended")
  }
}

extension KeystrokeLine {
  enum M15 {
    static let filterSuspended = FieldKey("filter_suspended")
  }
}
