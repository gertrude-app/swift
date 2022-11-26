import FluentSQL

public protocol SQLJoined: Decodable {
  static var query: String { get }
  static func decode(fromSqlRows rows: [SQLRow]) throws -> [Self]
  static func memoryQuery(bindings: [Postgres.Data]?) async throws -> [Self]
}

public extension SQLJoined {
  static func decode(fromSqlRows rows: [SQLRow]) throws -> [Self] {
    try rows.compactMap { row in
      try row.decode(model: Self.self, prefix: nil, keyDecodingStrategy: .convertFromSnakeCase)
    }
  }

  static func memoryQuery(bindings: [Postgres.Data]?) async throws -> [Self] {
    []
  }
}
