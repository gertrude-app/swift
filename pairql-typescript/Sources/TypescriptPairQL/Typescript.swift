@_exported import PairQL

public protocol TypescriptRepresentable {
  static var customTs: String? { get }
}

public protocol TypescriptPrimitive {
  static var tsPrimitiveType: String { get }
}

public protocol TypescriptPair: Pair
  where Input: TypescriptRepresentable, Output: TypescriptRepresentable {}

public typealias TypescriptPairInput = PairInput & TypescriptRepresentable
public typealias TypescriptPairOutput = PairOutput & TypescriptRepresentable
public typealias TypescriptNestable = PairNestable & TypescriptRepresentable

public protocol NamedType {
  static var __typeName: String { get }
}

public extension NamedType {
  static var __typeName: String { "\(Self.self)" }
}

public protocol GlobalType: TypescriptRepresentable {
  static var __typeName: String { get }
}

public extension GlobalType {
  static var __typeName: String { "\(Self.self)" }
}

// setting Input/Output to a typealias of a GlobalType causes ts derivation problems
// this struct is a workaround to allow derivation to succeed, passing thru the underlying type
public struct Alias<T: TypescriptNestable>: TypescriptNestable {
  private let value: T

  public static var customTs: String? { T.ts }

  public init(_ value: T) {
    self.value = value
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    value = try container.decode(T.self)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}

extension Alias: PairOutput {}
extension Alias: PairInput {}
