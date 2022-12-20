import PairQL
import Runtime

extension Union2: TypescriptRepresentable where A: TypescriptRepresentable,
  B: TypescriptRepresentable {
  public static var customTs: String? {
    """
    export type __self__ =
      | { type: "\(A.self)"; value: \(unnest(A.ts)) }
      | { type: "\(B.self)"; value: \(unnest(B.ts)) }
    """
  }
}

public extension TypescriptRepresentable {
  static var customTs: String? { nil }

  static var ts: String {
    var namedTypes: [String: String] = [:]
    var chunks: [String] = []
    chunks.append(derive(Self.self, &namedTypes))
    for (_, namedType) in namedTypes {
      chunks.append(namedType)
    }
    return chunks.reversed().joined(separator: "\n\n")
  }
}

private func derive(
  _ type: Any.Type,
  _ named: inout [String: String],
  resolveNamed: Bool = true
) -> String {
  if resolveNamed, let namedType = type as? NamedUnion.Type {
    let decl = derive(namedType, &named, resolveNamed: false)
      .replacingOccurrences(of: "__self__", with: namedType.__typeName)
    named["\(type)"] = decl
    return namedType.__typeName
  }

  if let repr = type as? TypescriptRepresentable.Type, let customTs = repr.customTs {
    return customTs
  }
  if let primitive = type as? TypescriptPrimitive.Type {
    return "export type __self__ = \(primitive.tsPrimitiveType);"
  }
  guard let info = try? typeInfo(of: type) else {
    return "export type __self__ = unknown; // !! runtime introspection failed"
  }

  if info.genericTypes.count == 1, info.name.starts(with: "Array<"),
     let element = info.genericTypes.first as? TypescriptRepresentable.Type {
    return "export type __self__ = Array<\(unnest(derive(element, &named)))>"
  }

  let props = info.properties
  var ts = "export interface __self__ {\n"
  for prop in props {
    ts += "  \(prop.name)\(tsProp(prop.type, &named))"
  }
  ts += "}"
  return ts
}

func tsProp(_ type: Any.Type, _ named: inout [String: String], optional: Bool = false) -> String {
  if let type = type as? TypescriptPrimitive.Type {
    return optional
      ? "?: " + type.tsPrimitiveType + ";\n"
      : ": " + type.tsPrimitiveType + ";\n"
  }

  if let info = try? typeInfo(of: type), info.kind == .optional {
    return tsProp(info.genericTypes[0], &named, optional: true)
  }

  if let nested = type as? TypescriptRepresentable.Type {
    return "\(optional ? "?" : ""): \(unnest(derive(nested, &named)));\n"
  }
  return ": unknown; // !! runtime introspection failed\n"
}

private func unnest(_ ts: String) -> String {
  ts
    .replacingOccurrences(of: "export interface __self__ ", with: "")
    .replacingOccurrences(of: "export type __self__ = ", with: "")
    .replacingOccurrences(of: "export type __self__ =", with: "")
    .replacingOccurrences(of: "\n", with: " ")
    .replacingOccurrences(of: "   ", with: " ")
}
