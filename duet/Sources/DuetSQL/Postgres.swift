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
  }
}

public extension Postgres.Data {
  var binding: any Sendable & Encodable {
    switch self {
    case .bool(let bool):
      return bool
    case .currentTimestamp:
      return "CURRENT_TIMESTAMP"
    case .date(let date):
      return date
    case .double(let double):
      return double
    case .enum(let enumVal):
      return enumVal?.rawValue
    case .float(let float):
      return float
    case .id(let model):
      return model.uuidId.uuidString
    case .int(let int):
      return int
    case .int64(let int64):
      return int64
    case .intArray(let ints):
      guard let ints else { return "NULL" }
      return "'{\(ints.map(String.init).joined(separator: ","))}'"
    case .json(let string):
      return string
    case .null:
      return "NULL"
    case .string(let string):
      return string
    case .uuid(let uuid):
      return uuid?.uuidString
    case .varchar(let string):
      return string
    }
  }
}

extension Postgres.Data: Equatable {
  public static func == (lhs: Postgres.Data, rhs: Postgres.Data) -> Bool {
    switch (lhs, rhs) {
    case (.id(let lhsId), .id(let rhsId)):
      lhsId.uuidId == rhsId.uuidId
    case (.string(let lhsVal), .string(let rhsVal)),
         (.json(let lhsVal), .json(let rhsVal)),
         (.varchar(let lhsVal), .varchar(let rhsVal)):
      lhsVal == rhsVal
    case (.intArray(let lhsVal), .intArray(let rhsVal)):
      lhsVal == rhsVal
    case (.int(let lhsVal), .int(let rhsVal)):
      lhsVal == rhsVal
    case (.int64(let lhsVal), .int64(let rhsVal)):
      lhsVal == rhsVal
    case (.float(let lhsVal), .float(let rhsVal)):
      lhsVal == rhsVal
    case (.double(let lhsVal), .double(let rhsVal)):
      lhsVal == rhsVal
    case (.uuid(let lhsVal), .uuid(let rhsVal)):
      lhsVal?.uuidString == rhsVal?.uuidString
    case (.bool(let lhsVal), .bool(let rhsVal)):
      lhsVal == rhsVal
    case (.date(let lhsVal), .date(let rhsVal)):
      lhsVal == rhsVal
    case (.enum(let lhsVal), .enum(let rhsVal)):
      lhsVal?.rawValue == rhsVal?.rawValue
    case (.null, .null):
      true
    case (.currentTimestamp, .currentTimestamp):
      true
    default:
      false
    }
  }
}

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
