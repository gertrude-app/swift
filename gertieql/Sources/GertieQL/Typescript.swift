public protocol TypescriptRepresentable {
  static var ts: String { get }
}

public typealias TypescriptPairInput = TypescriptRepresentable & Codable & Equatable

public protocol TypescriptPairOutput: PairOutput, TypescriptRepresentable {
  static var ts: String { get }
}

public protocol TypescriptPair: Pair
  where Input: TypescriptRepresentable, Output: TypescriptPairOutput {
  static var id: String { get }
  static var auth: ClientAuth { get }
}

public protocol TypescriptPrimitive {
  static var tsPrimitiveType: String { get }
}

extension String: TypescriptPrimitive {
  public static var tsPrimitiveType: String { "string" }
}

extension String: TypescriptRepresentable {
  public static var ts: String { "export type __self__ = \(tsPrimitiveType)" }
}

extension String: TypescriptPairOutput {}

extension Array: TypescriptRepresentable where Element: TypescriptPrimitive {
  public static var ts: String {
    "export type __self__ = \(Element.tsPrimitiveType)[]"
  }
}
