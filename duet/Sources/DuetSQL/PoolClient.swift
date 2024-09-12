import Duet
import PostgresKit

/// NB: uses @unchecked Sendable, may not be fully thread-safe
public struct ConnectionPoolClient: Client {
  private let box: Box

  public var pool: EventLoopGroupConnectionPool<PostgresConnectionSource> {
    self.box.pool
  }

  public var db: SQLDatabase {
    self.box.pool.database(logger: Logger(label: "duet.sql")).sql()
  }

  public init(pool: EventLoopGroupConnectionPool<PostgresConnectionSource>) {
    self.box = Box(pool: pool)
  }

  public func execute(statement: SQL.Statement) async throws -> [SQLRow] {
    #if !DEBUG
      return try await self.db.raw(statement.sql).all()
    #else
      do {
        return try await self.db.raw(statement.sql).all()
      } catch {
        print(String(reflecting: error))
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
        throw error
      }
    #endif
  }

  public func execute(raw: SQLQueryString) async throws -> [SQLRow] {
    try await self.db.raw(raw).all()
  }
}

extension ConnectionPoolClient {
  private final class Box: @unchecked Sendable {
    fileprivate let pool: EventLoopGroupConnectionPool<PostgresConnectionSource>

    init(pool: EventLoopGroupConnectionPool<PostgresConnectionSource>) {
      self.pool = pool
    }

    deinit {
      self.pool.shutdown()
    }
  }
}
