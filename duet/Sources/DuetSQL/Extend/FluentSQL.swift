import FluentSQL
import Foundation

public extension SQLRow {
  func decode<M: DuetSQL.Model>(_: M.Type) throws -> M {
    try decode(model: M.self, prefix: nil, keyDecodingStrategy: .convertFromSnakeCase)
  }
}

public extension SQLQueryString {
  mutating func appendInterpolation<T: RawRepresentable>(id: T) where T.RawValue == UUID {
    appendInterpolation(uuid: id.rawValue)
  }

  mutating func appendInterpolation(uuid: UUID) {
    appendInterpolation(unsafeRaw: uuid.uuidString)
  }

  mutating func appendInterpolation<M: DuetSQL.Model>(table model: M.Type) {
    appendInterpolation(unsafeRaw: model.tableName)
  }

  mutating func appendInterpolation(escaping string: String) {
    appendInterpolation(unsafeRaw: string.replacingOccurrences(of: "'", with: "''"))
  }

  mutating func appendInterpolation(col: FieldKey) {
    appendInterpolation(unsafeRaw: col.description)
  }

  mutating func appendInterpolation(col: String) {
    appendInterpolation(unsafeRaw: col)
  }

  mutating func appendInterpolation(timestamp date: Date) {
    appendInterpolation(unsafeRaw: date.postgresTimestampString)
  }

  mutating func appendInterpolation(nullable: String?) {
    if let string = nullable {
      appendInterpolation(unsafeRaw: "'")
      appendInterpolation(unsafeRaw: string.replacingOccurrences(of: "'", with: "''"))
      appendInterpolation(unsafeRaw: "'")
    } else {
      appendInterpolation(unsafeRaw: "NULL")
    }
  }

  mutating func appendInterpolation(nullable: Int?) {
    if let string = nullable {
      appendInterpolation(literal: string)
    } else {
      appendInterpolation(unsafeRaw: "NULL")
    }
  }
}
