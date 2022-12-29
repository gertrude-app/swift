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

public protocol SharedType: TypescriptRepresentable {
  static var __typeName: String { get }
}

public extension SharedType {
  static var __typeName: String { "\(Self.self)" }
}
