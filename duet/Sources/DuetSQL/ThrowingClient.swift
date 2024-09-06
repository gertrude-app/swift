import Duet
import PostgresKit

public struct ThrowingClient: Client {
  struct Error: Swift.Error {
    var message: String
  }

  public func execute(statement: SQL.Statement) async throws -> [SQLRow] {
    throw Error(message: "DuetSQL.ThrowingClient.execute(statement:) not implemented")
  }

  public func execute<M: Model>(statement: SQL.Statement, returning: M.Type) async throws -> [M] {
    throw Error(message: "DuetSQL.ThrowingClient.execute(statement:returning:) not implemented")
  }

  public func execute(raw: SQLQueryString) async throws -> [SQLRow] {
    throw Error(message: "DuetSQL.ThrowingClient.execute(raw:) not implemented")
  }

  public init() {}
}
