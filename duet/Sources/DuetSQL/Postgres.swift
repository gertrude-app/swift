import Duet
import Foundation
import XCore

public protocol PostgresEnum: Sendable {
  var typeName: String { get }
  var rawValue: String { get }
}

public extension PostgresEnum where Self: CaseIterable {
  static var typeName: String {
    guard let first = allCases.first else {
      fatalError("PostgresEnum \(Self.self) has no cases")
    }
    return first.typeName
  }
}

public protocol PostgresJsonable: Codable {}

public extension PostgresJsonable {
  var toPostgresJson: String { try! JSON.encode(self) }
  init(fromPostgresJson json: String) throws {
    self = try JSONDecoder().decode(Self.self, from: json.data(using: .utf8)!)
  }
}

public enum Postgres {
  public static let MAX_BIND_PARAMS = Int(INT16_MAX)

  public enum Columns {
    case all
    case columns([String])

    public var sql: String {
      switch self {
      case .all:
        return "*"
      case .columns(let columns):
        return "\"\(columns.joined(separator: "\", \""))\""
      }
    }
  }

  public enum Data: Sendable {
    case id(UUIDIdentifiable)
    case string(String?)
    case varchar(String?)
    case intArray([Int]?)
    case int(Int?)
    case int64(Int64?)
    case float(Float?)
    case double(Double?)
    case uuid(UUIDStringable?)
    case bool(Bool?)
    case date(Date?)
    case `enum`(PostgresEnum?)
    case json(String?)
    case null
    case currentTimestamp

    public var holdsNull: Bool {
      switch self {
      case .id, .currentTimestamp, .null:
        return false
      case .string(let wrapped):
        return wrapped == nil
      case .varchar(let wrapped):
        return wrapped == nil
      case .intArray(let wrapped):
        return wrapped == nil
      case .int(let wrapped):
        return wrapped == nil
      case .int64(let wrapped):
        return wrapped == nil
      case .float(let wrapped):
        return wrapped == nil
      case .double(let wrapped):
        return wrapped == nil
      case .uuid(let wrapped):
        return wrapped == nil
      case .bool(let wrapped):
        return wrapped == nil
      case .date(let wrapped):
        return wrapped == nil
      case .enum(let wrapped):
        return wrapped == nil
      case .json(let wrapped):
        return wrapped == nil
      }
    }

    public var typeName: String {
      switch self {
      case .string:
        return "text"
      case .varchar:
        return "varchar"
      case .int, .int64, .double, .float:
        return "numeric"
      case .intArray:
        return "numeric[]"
      case .uuid, .id:
        return "uuid"
      case .bool:
        return "bool"
      case .enum(let enumVal):
        return enumVal?.typeName ?? "unknown"
      case .null:
        return "unknown"
      case .date:
        return "timestamp with time zone"
      case .json:
        return "jsonb"
      case .currentTimestamp:
        return "timestamp with time zone"
      }
    }

    public var param: String {
      switch self {
      case .enum(let enumVal):
        return nullable(enumVal?.rawValue)
      case .string(let string):
        return nullable(string)
      case .varchar(let string):
        return nullable(string)
      case .int64(let int64):
        return nullable(int64)
      case .int(let int):
        return nullable(int)
      case .float(let float):
        return nullable(float)
      case .double(let double):
        return nullable(double)
      case .intArray(let ints):
        guard let ints = ints else { return "NULL" }
        return "'{\(ints.map(String.init).joined(separator: ","))}'"
      case .id(let model):
        return "'\(model.uuidId.uuidString)'"
      case .uuid(let uuid):
        return nullable(uuid?.uuidString)
      case .bool(let bool):
        return nullable(bool)
      case .json(let string):
        return nullable(string)
      case .date(let date):
        return nullable(date)
      case .null:
        return "NULL"
      case .currentTimestamp:
        return "current_timestamp"
      }
    }
  }
}

// extensions

extension Postgres.Data: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .string(value)
  }
}

extension Postgres.Data: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self = .int(value)
  }
}

extension Postgres.Data: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

extension Postgres.Data: Equatable {
  public static func == (lhs: Postgres.Data, rhs: Postgres.Data) -> Bool {
    [lhs.typeName, lhs.param] == [rhs.typeName, rhs.param]
  }
}

extension Postgres.Data: Comparable {
  public static func < (lhs: Postgres.Data, rhs: Postgres.Data) -> Bool {
    switch (lhs, rhs) {
    case (.id(let left), .id(let right)):
      return left.uuidId.uuidString < right.uuidId.uuidString
    case (.uuid(let left), .uuid(let right)):
      return left?.uuidString ?? "" < right?.uuidString ?? ""

    case (.json, .json):
      assertionFailure("cannot compare to Postgres.Data.json values")
      return false
    case (.null, .null):
      assertionFailure("cannot compare to Postgres.Data.null values")
      return false
    case (.currentTimestamp, .currentTimestamp):
      assertionFailure("cannot compare to Postgres.Data.currentTimestamp values")
      return false
    case (.intArray, .intArray):
      assertionFailure("cannot compare to Postgres.Data.intArray values")
      return false

    case (.string(nil), .string(nil)):
      return false
    case (.string(nil), .string):
      return true
    case (.string, .string(nil)):
      return false
    case (.string(let left), .string(let right)):
      return left ?? "" < right ?? ""

    case (.int(nil), .int(nil)):
      return false
    case (.int(nil), .int):
      return true
    case (.int, .int(nil)):
      return false
    case (.int(let left), .int(let right)):
      return left ?? 0 < right ?? 0

    case (.float(nil), .float(nil)):
      return false
    case (.float(nil), .float):
      return true
    case (.float, .float(nil)):
      return false
    case (.float(let left), .float(let right)):
      return left ?? 0.0 < right ?? 0.0

    case (.bool(nil), .bool(nil)):
      return false
    case (.bool(nil), .bool):
      return true
    case (.bool, .bool(nil)):
      return false
    case (.bool(let left), .bool(let right)):
      return left == right ? false : left == false

    case (.enum(nil), .enum(nil)):
      return false
    case (.enum(nil), .enum):
      return true
    case (.enum, .enum(nil)):
      return false
    case (.enum(let left), .enum(let right)):
      return left?.rawValue ?? "" < right?.rawValue ?? ""

    case (.date(let left), .date(let right)):
      guard let left = left, let right = right else {
        return false
      }
      return left < right
    case (.date(let left), .currentTimestamp):
      if let left = left {
        return left < Date()
      }
      return false
    case (.currentTimestamp, .date(let right)):
      if let right = right {
        return Date() < right
      }
      return false

    default:
      assertionFailure("cannot compare two Postgres.Data values of different type")
      return false
    }
  }
}

// helpers

private func nullable(_ string: String?) -> String {
  switch string {
  case nil:
    return "NULL"
  case .some(let string):
    return "'\(string.replacingOccurrences(of: "'", with: "''"))'"
  }
}

private func nullable(_ bool: Bool?) -> String {
  switch bool {
  case nil:
    return "NULL"
  case .some(let bool):
    return bool ? "true" : "false"
  }
}

private func nullable(_ date: Date?) -> String {
  switch date {
  case nil:
    return "NULL"
  case .some(let date):
    return "'\(date.postgresTimestampString)'"
  }
}

private func nullable<N: Numeric>(_ string: N?) -> String {
  switch string {
  case nil:
    return "NULL"
  case .some(let number):
    return "\(number)"
  }
}
