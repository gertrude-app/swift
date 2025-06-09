import DuetSQL
import FluentSQL
import Vapor

extension SQLDatabase {
  @discardableResult
  func execute(_ sql: SQLQueryString) async throws -> [SQLRow] {
    if ProcessInfo.processInfo.environment["MIGRATE_LOG_SQL"] != nil {
      var serializer = SQLSerializer(database: self)
      sql.serialize(to: &serializer)
      print("\n\(serializer.sql)")
    }
    return try await raw(sql).all()
  }
}
