import PostgresKit

public protocol CustomQueryable: Decodable, Sendable {
  static func query(bindings: [Postgres.Data]) -> SQLQueryString
  static func decode(from rows: [SQLRow]) throws -> [Self]
}

public extension CustomQueryable {
  static func decode(from rows: [SQLRow]) throws -> [Self] {
    try rows.compactMap { row in
      try row.decode(
        model: Self.self,
        prefix: nil,
        keyDecodingStrategy: .convertFromSnakeCase
      )
    }
  }
}
