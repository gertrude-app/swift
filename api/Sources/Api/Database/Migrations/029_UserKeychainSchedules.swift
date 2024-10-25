import FluentSQL
import Foundation
import Gertie

struct UserKeychainSchedules: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      UserKeychain.M29.schedule,
      on: UserKeychain.M3.self,
      type: .jsonb,
      nullable: true
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(
      UserKeychain.M29.schedule,
      on: UserKeychain.M3.self
    )
  }
}

extension UserKeychain {
  enum M29 {
    static let schedule = FieldKey("schedule")
  }
}
