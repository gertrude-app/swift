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

extension Array: TypescriptRepresentable where Element: TypescriptRepresentable {}

extension Dictionary: PairOutput where Key == String, Value == String {}

extension Dictionary: PairInput where Key == String, Value == String {}

extension Dictionary: TypescriptRepresentable where Key == String, Value == String {}

extension UUID: TypescriptRepresentable {}

extension URL: TypescriptRepresentable {}

extension SuccessOutput: TypescriptRepresentable {}

extension NoInput: TypescriptRepresentable {
  public static var ts: String { "type __self___ = never;" }
}

extension ClientAuth: TypescriptRepresentable {
  public static var customTs: String? {
    guard let info = try? typeInfo(of: ClientAuth.self) else {
      return "export type ClientAuth = never; // !! runtime introspection failed"
    }
    return """
    export enum ClientAuth {
      \(info.cases.map(\.name).joined(separator: ",\n  ")),
    }
    """
  }
}
