import PairQL
import Runtime

public extension TypescriptRepresentable {
  static var ts: String {
    if let type = Self.self as? TypescriptPrimitive.Type {
      return "export type __self__ = \(type.tsPrimitiveType);"
    }
    guard let info = try? typeInfo(of: Self.self) else {
      return "export type __self__ = unknown; // !! runtime introspection failed"
    }
    let props = info.properties
    var ts = "export interface __self__ {\n"
    for prop in props {
      ts += "  \(prop.name)\(toTs(prop.type))"
    }
    ts += "}"
    return ts
  }
}

func toTs(_ type: Any.Type, optional: Bool = false) -> String {
  if let type = type as? TypescriptPrimitive.Type {
    return optional
      ? "?: " + type.tsPrimitiveType + ";\n"
      : ": " + type.tsPrimitiveType + ";\n"
  }

  if let info = try? typeInfo(of: type), info.kind == .optional {
    return toTs(info.genericTypes[0], optional: true)
  }

  if let nested = type as? TypescriptRepresentable.Type {
    let short = nested.ts
      .replacingOccurrences(of: "export interface __self__ ", with: "")
      .replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "   ", with: " ")
    return "\(optional ? "?" : ""): \(short);\n"
  }
  return ": unknown; // !! runtime introspection failed\n"
}
