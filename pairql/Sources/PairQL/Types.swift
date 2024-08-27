import Foundation

#if os(Linux)
  extension JSONEncoder: @unchecked Sendable {}
  extension JSONDecoder.DateDecodingStrategy: @unchecked Sendable {}
#endif

@_exported import CasePaths
@_exported import URLRouting

public protocol PairRoute: Equatable {}

public typealias PairNestable = Codable & Equatable & Sendable

public protocol PairInput: Codable, Equatable, Sendable {}

public protocol PairOutput: Codable, Equatable, Sendable {
  func jsonData() throws -> Data
}

public protocol Pair {
  static var name: String { get }
  static var auth: ClientAuth { get }
  associatedtype Input: PairInput = NoInput
  associatedtype Output: PairOutput = SuccessOutput
}

public extension Pair {
  static var name: String { "\(Self.self)" }
}

public enum ClientAuth: String, Sendable {
  case none
  case user
  case admin
  case superAdmin
}

public struct PairJsonEncodingError: Error {}

private let encoder = { () -> JSONEncoder in
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601
  return encoder
}()

public extension PairOutput {
  func jsonData() throws -> Data {
    try encoder.encode(self)
  }

  func json() throws -> String {
    guard let json = String(data: try jsonData(), encoding: .utf8) else {
      throw PairJsonEncodingError()
    }
    return json
  }
}

extension Array: PairOutput where Element: PairOutput {}
extension Array: PairInput where Element: PairInput {}
extension Dictionary: PairOutput where Key == String, Value: PairOutput {}
extension Dictionary: PairInput where Key == String, Value: PairInput {}

public struct NoInput: PairInput {
  public init() {}
}

public struct SuccessOutput: PairOutput {
  public let success: Bool

  public init(_ success: Bool) {
    self.success = success
  }

  public init() {
    self.success = true
  }

  public static var success: Self { .init(true) }
  public static var failure: Self { .init(false) }
}

extension String: PairOutput {}
extension String: PairInput {}
extension UUID: PairInput {}
extension UUID: PairOutput {}

public struct Operation<P: Pair>: ParserPrinter {
  private var pair: P.Type

  public init(_ pair: P.Type) {
    self.pair = pair
  }

  public func parse(_ input: inout URLRequestData) throws {
    try Path { pair.name }.parse(&input)
  }

  public func print(_ output: Void, into input: inout URLRequestData) throws {
    try Path { pair.name }.print(output, into: &input)
  }
}

public extension Conversion {
  static func input<P: Pair>(
    _ Pair: P.Type,
    dateDecodingStrategy strategy: JSONDecoder.DateDecodingStrategy? = nil
  ) -> Self where Self == Conversions.JSON<P.Input> {
    if let strategy = strategy {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = strategy
      return .init(Pair.Input, decoder: decoder)
    }
    return .init(Pair.Input)
  }
}
