import FluentSQL

public protocol CustomQueryable: Decodable, Sendable {
  static func query(numBindings: Int) -> String
  static func decode(fromSqlRows rows: [SQLRow]) throws -> [Self]
}

public extension CustomQueryable {
  static func decode(fromSqlRows rows: [SQLRow]) throws -> [Self] {
    try rows.compactMap { row in
      try row.decode(model: Self.self, prefix: nil, keyDecodingStrategy: .convertFromSnakeCase)
    }
  }
}
