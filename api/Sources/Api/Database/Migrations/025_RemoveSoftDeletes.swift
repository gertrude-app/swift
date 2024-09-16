import FluentSQL
import Foundation
import Gertie

struct RemoveSoftDeletes: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.dropColumn(.deletedAt, on: User.M3.self)
    try await sql.dropColumn(.deletedAt, on: Keychain.M2.self)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.addColumn(
      .deletedAt,
      on: User.M3.self,
      type: .timestampWithTimezone,
      nullable: true
    )
    try await sql.addColumn(
      .deletedAt,
      on: Keychain.M2.self,
      type: .timestampWithTimezone,
      nullable: true
    )
  }
}
