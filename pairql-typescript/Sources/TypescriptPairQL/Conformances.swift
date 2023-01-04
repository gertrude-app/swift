import Foundation
import PairQL
import Runtime

extension UUID: TypescriptPrimitive {
  public static var tsPrimitiveType: String { "UUID" }
}

extension String: TypescriptPrimitive {
  public static var tsPrimitiveType: String { "string" }
}

extension Int: TypescriptPrimitive {
  public static var tsPrimitiveType: String { "number" }
}

extension Bool: TypescriptPrimitive {
  public static var tsPrimitiveType: String { "boolean" }
}

extension URL: TypescriptPrimitive {
  public static var tsPrimitiveType: String { "string" }
}

extension Date: TypescriptPrimitive {
  public static var tsPrimitiveType: String { "ISODateString" }
}

extension Array: TypescriptPrimitive where Element: TypescriptPrimitive {
  public static var tsPrimitiveType: String {
    "\(Element.tsPrimitiveType)[]"
  }
}

extension Dictionary: TypescriptPrimitive where Key: TypescriptPrimitive,
  Value: TypescriptPrimitive {
  public static var tsPrimitiveType: String {
    "{ [key: \(Key.tsPrimitiveType)]: \(Value.tsPrimitiveType); }"
  }
}

extension Int: TypescriptRepresentable {}

extension String: TypescriptRepresentable {}

extension Bool: TypescriptRepresentable {}

extension Date: TypescriptRepresentable {}

extension Array: TypescriptRepresentable where Element: TypescriptRepresentable {}

extension Dictionary: PairOutput where Key == String, Value == String {}

extension Dictionary: PairInput where Key == String, Value == String {}

extension Dictionary: TypescriptRepresentable where Key == String, Value == String {}

extension UUID: TypescriptRepresentable {}

extension URL: TypescriptRepresentable {}

extension SuccessOutput: TypescriptRepresentable {
  public static var customTs: String? { "export type __self__ = SuccessOutput;" }
}

extension NoInput: TypescriptRepresentable {
  public static var customTs: String? { "export type __self__ = void;" }
}

extension ClientAuth: TypescriptRepresentable {}
