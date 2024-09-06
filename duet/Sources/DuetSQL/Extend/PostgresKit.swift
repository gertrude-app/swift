import PostgresKit

public extension SQLRow {
  func decode<M: DuetSQL.Model>(_: M.Type) throws -> M {
    try self.decode(model: M.self, prefix: nil, keyDecodingStrategy: .convertFromSnakeCase)
  }
}

extension SQLQueryString {
  mutating func appendInterpolation(expression: DuetSqlExpression) {
    self.appendInterpolation(expression)
  }
}

enum DuetSqlExpression: SQLExpression {
  case uuid(String)
  case date(Date)
  case currentTimestamp
  case null
  case customEnum(String, String)
  case jsonb(String)

  func serialize(to serializer: inout SQLSerializer) {
    switch self {
    case .uuid(let uuid):
      serializer.write("'\(uuid)'::uuid")
    case .date(let date):
      serializer.write("'\(date)'::timestamptz")
    case .jsonb(let json):
      serializer.write("'\(json)'::jsonb")
    case .customEnum(let typeName, let value):
      serializer.write("'\(value)'::\(typeName)")
    case .currentTimestamp:
      serializer.write("CURRENT_TIMESTAMP")
    case .null:
      serializer.write("NULL")
    }
  }
}
