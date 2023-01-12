import Foundation

public extension Log {
  typealias Meta = [String: MetaValue]

  enum MetaValue {
    case string(String)
    case bool(Bool)
    case int(Int)
    case float(Double)
  }
}

extension Log.MetaValue: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

extension Log.MetaValue: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self = .int(value)
  }
}

extension Log.MetaValue: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) {
    self = .float(value)
  }
}

extension Log.MetaValue: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .string(value)
  }
}

extension Log.MetaValue: Equatable {}

extension Log.MetaValue: CustomStringConvertible {
  public var description: String {
    switch self {
    case .string(let string):
      return string
    case .bool(let bool):
      return bool ? "true" : "false"
    case .int(let value):
      return "\(value)"
    case .float(let value):
      return "\(value)"
    }
  }
}

extension Log.MetaValue: Codable {
  public func encode(to encoder: Encoder) throws {
    switch self {
    case .string(let string):
      if string.count >= 1024 * 64 {
        try (string.prefix(1024 * 64 - 10) + "[...]").encode(to: encoder)
      } else {
        try string.encode(to: encoder)
      }
    case .bool(let bool):
      try bool.encode(to: encoder)
    case .int(let int):
      try int.encode(to: encoder)
    case .float(let float):
      try float.encode(to: encoder)
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let string = try? container.decode(String.self) {
      self = .string(string)
    } else if let int = try? container.decode(Int.self) {
      self = .int(int)
    } else if let float = try? container.decode(Double.self) {
      self = .float(float)
    } else {
      let bool = try container.decode(Bool.self)
      self = .bool(bool)
    }
  }
}

public extension Log.MetaValue {
  init(_ string: String?) {
    self = .string(string ?? "(nil)")
  }

  init<T: Encodable>(_ value: T?) {
    let encoded = (try? JSONEncoder().encode(value)).flatMap { String(data: $0, encoding: .utf8) }
    self = .string(encoded ?? "(encode failure)")
  }
}

public func + (lhs: Log.Meta?, rhs: Log.Meta) -> Log.Meta {
  guard var result = lhs else { return rhs }
  for (key, value) in rhs {
    result[key] = value
  }
  return result
}

public extension Dictionary where Key == String, Value == Log.MetaValue {
  static func error(_ error: Error?) -> Self {
    [
      "error.swift_type": error
        .map { .string(String(describing: type(of: $0))) } ?? .string("(nil)"),
      "error.debug_description": error
        .map { .string(String(describing: $0)) } ?? .string("(nil)"),
    ]
  }

  static func json(_ json: String?) -> Self {
    ["json.raw": .string(json ?? "(nil)")]
  }
  
  static func primary(_ string: String) -> Self {
    ["meta.primary": .string(string)]
  }

  static func primary<T: Encodable>(_ data: T) -> Self {
    let encoded = (try? JSONEncoder().encode(data))
      .flatMap { String(data: $0, encoding: .utf8) }
    return ["meta.primary": .init(encoded)]
  }

  static func userId(_ userId: uid_t) -> Self {
    .primary("{\"user_id\": \(userId)}")
  }
}
