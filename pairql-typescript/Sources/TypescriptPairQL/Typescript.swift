@_exported import PairQL

public protocol TypescriptRepresentable {
  static var ts: String { get }
}

public protocol TypescriptPrimitive {
  static var tsPrimitiveType: String { get }
}

public protocol TypescriptPair: Pair
  where Input: TypescriptRepresentable, Output: TypescriptRepresentable {}

public typealias TypescriptPairInput = PairInput & TypescriptRepresentable
public typealias TypescriptPairOutput = PairOutput & TypescriptRepresentable
