import FluentSQL

struct AddReleaseNotes: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      Release.M12.notes,
      on: Release.M7.self,
      type: .text,
      nullable: true
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(Release.M12.notes, on: Release.M7.self)
  }
}

extension Release {
  enum M12 {
    static let notes = FieldKey("notes")
  }
}
