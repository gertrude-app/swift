import Dependencies
import FluentSQL
import Foundation

struct SearchPaths: GertieMigration {
  @Dependency(\.env) var env

  func up(sql: SQLDatabase) async throws {
    let paths = "public, parent, child, iosapp, macapp, macos, system"
    try await setPaths(to: paths, sql: sql)
  }

  func down(sql: SQLDatabase) async throws {
    let paths = "\"$user\", public"
    try await setPaths(to: paths, sql: sql)
  }

  func setPaths(to paths: String, sql: SQLDatabase) async throws {
    try await sql.execute("""
      SET search_path TO \(unsafeRaw: paths);
    """)

    try await sql.execute("""
      ALTER USER \(unsafeRaw: self.env.database.username)
      SET search_path TO \(unsafeRaw: paths);
    """)

    try await sql.execute("""
      ALTER DATABASE \(unsafeRaw: self.env.database.name)
      SET search_path TO \(unsafeRaw: paths);
    """)
  }
}
