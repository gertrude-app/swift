import FluentSQL
import Foundation
import Gertie

struct ScheduleFeatures: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      UserKeychain.M29.schedule,
      on: UserKeychain.M3.self,
      type: .jsonb,
      nullable: true
    )
    try await sql.addColumn(
      User.M29.downtime,
      on: User.M3.self,
      type: .jsonb,
      nullable: true
    )
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.dropColumn(
      UserKeychain.M29.schedule,
      on: UserKeychain.M3.self
    )
    try await sql.dropColumn(
      User.M29.downtime,
      on: User.M3.self
    )
  }
}

extension UserKeychain {
  enum M29 {
    static let schedule = FieldKey("schedule")
  }
}

extension User {
  enum M29 {
    static let downtime = FieldKey("downtime")
  }
}
