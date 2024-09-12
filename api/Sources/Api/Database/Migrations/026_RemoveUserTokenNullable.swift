import FluentSQL
import Foundation
import Gertie

struct RemoveUserTokenNullable: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    // as of 9/2024 all the rows that have null here are 2+ years old, not in use
    try await sql.execute("""
      DELETE FROM \(table: UserToken.M3.self)
      WHERE \(col: UserToken.M11.userDeviceId) IS NULL
    """)
    try await sql.add(constraint: .notNull(UserToken.M3.self, UserToken.M11.userDeviceId))
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.drop(constraint: .notNull(UserToken.M3.self, UserToken.M11.userDeviceId))
  }
}
