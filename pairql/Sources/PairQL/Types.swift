import Foundation

@_exported import CasePaths
@_exported import URLRouting

public protocol PairRoute: Equatable {}

public protocol PairInput: Codable, Equatable {}

public protocol PairOutput: Codable, Equatable {
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

public enum ClientAuth: String {
  case none
  case user
  case admin
}

public struct PairJsonEncodingError: Error {}

public extension PairOutput {
  func jsonData() throws -> Data {
    try JSONEncoder().encode(self)
  }

  func json() throws -> String {
    guard let json = String(data: try jsonData(), encoding: .utf8) else {
      throw PairJsonEncodingError()
    }
    return json
  }
}

extension Array: PairOutput where Element: PairOutput {}

public struct NoInput: PairInput {
  public init() {}
}

public struct SuccessOutput: PairOutput {
  public let success: Bool

  public init(_ success: Bool) {
    self.success = success
  }
}

extension Array: PairInput where Element == String {}
extension String: PairOutput {}
extension UUID: PairInput {}

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
