import Duet
import PostgresKit

public struct SQLDatabaseClient: Client {
  public let db: any SQLDatabase

  public init(db: any SQLDatabase) {
    self.db = db
  }

  public func execute(statement: SQL.Statement) async throws -> [SQLRow] {
    #if !DEBUG
      return try await self.db.raw(statement.sql).all()
    #else
      do {
        return try await self.db.raw(statement.sql).all()
      } catch {
        print(String(reflecting: error))
        #if !os(Linux)
          fflush(stdout)
        #endif
        throw error
      }
    #endif
  }

  public func execute<M: Model>(statement: SQL.Statement, returning: M.Type) async throws -> [M] {
    #if !DEBUG
      let rows = try await self.db.raw(statement.sql).all()
      return try rows.compactMap { row in try row.decode(M.self) }
    #else
      do {
        let rows = try await self.db.raw(statement.sql).all()
        return try rows.compactMap { row in try row.decode(M.self) }
      } catch {
        print(String(reflecting: error))
        #if !os(Linux)
          fflush(stdout)
        #endif
        throw error
      }
    #endif
  }

  public func execute(raw: SQLQueryString) async throws -> [SQLRow] {
    try await self.db.raw(raw).all()
  }
}
