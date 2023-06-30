import FluentSQL
import XCore

struct AddReleaseRequirementPace: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      Release.M9.requirementPace,
      on: Release.M7.self,
      type: .int,
      nullable: true,
      default: .int(10)
    )
    try await sql.dropColumn(Release.M7.coreRevision, on: Release.M7.self)
    try await sql.renameColumn(
      on: Release.M7.self,
      from: Release.M7.appRevision,
      to: Release.M9.revision
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(Release.M9.requirementPace, on: Release.M7.self)
    try await sql.addColumn(
      Release.M7.coreRevision,
      on: Release.M7.self,
      type: .text,
      default: .text("unknown")
    )
    try await sql.renameColumn(
      on: Release.M7.self,
      from: Release.M9.revision,
      to: Release.M7.appRevision
    )
  }
}

// extensions

extension Release {
  enum M9 {
    static let requirementPace = FieldKey("requirement_pace")
    static let revision = FieldKey("revision")
  }
}
