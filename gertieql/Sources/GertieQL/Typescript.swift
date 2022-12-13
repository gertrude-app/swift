import Foundation

public protocol TypescriptRepresentable {
  static var ts: String { get }
}

public typealias TypescriptPairInput = PairInput & TypescriptRepresentable
public typealias TypescriptPairOutput = PairOutput & TypescriptRepresentable

public protocol TypescriptPair: Pair
  where Input: TypescriptRepresentable, Output: TypescriptRepresentable {}

public protocol TypescriptPrimitive {
  static var tsPrimitiveType: String { get }
}

extension String: TypescriptPrimitive {
  public static var tsPrimitiveType: String { "string" }
}

extension String: TypescriptRepresentable {
  public static var ts: String { "export type __self__ = \(tsPrimitiveType)" }
}

extension Array: TypescriptRepresentable where Element: TypescriptPrimitive {
  public static var ts: String {
    "export type __self__ = \(Element.tsPrimitiveType)[]"
  }
}

extension Dictionary: PairOutput where Key == String, Value == String {}
extension Dictionary: PairInput where Key == String, Value == String {}

extension Dictionary: TypescriptRepresentable where Key == String, Value == String {
  public static var ts: String { "export type __self__ = Record<string, string>" }
}

extension UUID: TypescriptRepresentable {
  public static var ts: String { "export type __self__ = string" }
}

extension NoInput: TypescriptRepresentable {
  public static var ts: String { "type __self___ = never;" }
}

extension SuccessOutput: TypescriptRepresentable {
  public static var ts: String {
    """
    interface __self__ {
      success: boolean;
    }
    """
  }
}

extension ClientAuth: TypescriptRepresentable {
  public static var ts: String {
    """
    export enum ClientAuth {
      none,
      user,
      admin,
    }
    """
  }
}
