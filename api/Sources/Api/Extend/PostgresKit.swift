import FluentKit
import Foundation
import PostgresKit

public extension SQLQueryString {
  mutating func appendInterpolation<T: RawRepresentable>(id: T) where T.RawValue == UUID {
    self.appendInterpolation(uuid: id.rawValue)
  }

  mutating func appendInterpolation(uuid: UUID) {
    self.appendInterpolation(unsafeRaw: uuid.uuidString)
  }

  mutating func appendInterpolation(escaping string: String) {
    self.appendInterpolation(unsafeRaw: string.replacingOccurrences(of: "'", with: "''"))
  }

  mutating func appendInterpolation(col: String) {
    self.appendInterpolation(unsafeRaw: col)
  }

  mutating func appendInterpolation(col: FieldKey) {
    self.appendInterpolation(unsafeRaw: col.description)
  }

  mutating func appendInterpolation(timestamp date: Date) {
    self.appendInterpolation(unsafeRaw: date.postgresTimestampString)
  }

  mutating func appendInterpolation(nullable: String?) {
    if let string = nullable {
      self.appendInterpolation(unsafeRaw: "'")
      self.appendInterpolation(unsafeRaw: string.replacingOccurrences(of: "'", with: "''"))
      self.appendInterpolation(unsafeRaw: "'")
    } else {
      self.appendInterpolation(unsafeRaw: "NULL")
    }
  }
}
