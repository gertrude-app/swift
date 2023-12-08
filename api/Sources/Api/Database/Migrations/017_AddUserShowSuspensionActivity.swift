import FluentSQL
import Gertie

struct AddUserShowSuspensionActivity: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      User.M17.showSuspensionActivity,
      on: User.M3.self,
      type: .boolean,
      default: .boolean(true)
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(
      User.M17.showSuspensionActivity,
      on: User.M3.self
    )
  }
}

extension User {
  enum M17 {
    static let showSuspensionActivity = FieldKey("show_suspension_activity")
  }
}
