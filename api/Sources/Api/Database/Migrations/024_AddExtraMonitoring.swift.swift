import DuetSQL
import FluentSQL
import Gertie

struct AddExtraMonitoring: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      SuspendFilterRequest.M24.extraMonitoring,
      on: SuspendFilterRequest.M5.self,
      type: .varchar(255),
      nullable: true
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(
      SuspendFilterRequest.M24.extraMonitoring,
      on: SuspendFilterRequest.M5.self
    )
  }
}

extension SuspendFilterRequest {
  enum M24 {
    static let extraMonitoring = FieldKey("extra_monitoring")
  }
}
