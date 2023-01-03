import PairQL
import Runtime

extension Union2: TypescriptRepresentable where
  T1: TypescriptRepresentable,
  T2: TypescriptRepresentable {
  public static var customTs: String? {
    """
    export type __self__ =
      | { type: "\(T1.self)"; value: \(unnest(T1.ts)) }
      | { type: "\(T2.self)"; value: \(unnest(T2.ts)) }
    """
  }
}

extension Union3: TypescriptRepresentable where
  T1: TypescriptRepresentable,
  T2: TypescriptRepresentable,
  T3: TypescriptRepresentable {
  public static var customTs: String? {
    """
    export type __self__ =
      | { type: "\(T1.self)"; value: \(unnest(T1.ts)) }
      | { type: "\(T2.self)"; value: \(unnest(T2.ts)) }
      | { type: "\(T3.self)"; value: \(unnest(T3.ts)) }
    """
  }
}

// TODO: delete me
extension Union6: TypescriptRepresentable where
  T1: TypescriptRepresentable,
  T2: TypescriptRepresentable,
  T3: TypescriptRepresentable,
  T4: TypescriptRepresentable,
  T5: TypescriptRepresentable,
  T6: TypescriptRepresentable {
  public static var customTs: String? {
    """
    export type __self__ =
      | { type: "\(T1.self)"; value: \(unnest(T1.ts)) }
      | { type: "\(T2.self)"; value: \(unnest(T2.ts)) }
      | { type: "\(T3.self)"; value: \(unnest(T3.ts)) }
      | { type: "\(T4.self)"; value: \(unnest(T4.ts)) }
      | { type: "\(T5.self)"; value: \(unnest(T5.ts)) }
      | { type: "\(T6.self)"; value: \(unnest(T6.ts)) }
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
  _ depth: Int = 0,
  resolveNamed: Bool = true
) -> String {
  if "\(type)".hasPrefix("Alias<"),
     let info = try? typeInfo(of: type),
     info.genericTypes.count == 1, info.name.starts(with: "Alias<"),
     let element = info.genericTypes.first {
    return "export type __self__ = " + derive(element, &named, depth + 1)
  }

  var derivingRootGlobalType = false
  var sharedTypeName: String?
  if let sharedType = type as? GlobalType.Type {
    if depth == 0 {
      derivingRootGlobalType = true
      sharedTypeName = sharedType.__typeName
    } else {
      return sharedType.__typeName
    }
  }

  if resolveNamed, let namedType = type as? NamedType.Type {
    let decl = derive(namedType, &named, depth + 1, resolveNamed: false)
    named["\(type)"] = identify(decl, namedType.__typeName)
    return namedType.__typeName
  }

  if let repr = type as? TypescriptRepresentable.Type, let customTs = repr.customTs {
    return derivingRootGlobalType ? identify(customTs, sharedTypeName ?? "\(type)") : customTs
  }

  if let primitive = type as? TypescriptPrimitive.Type {
    return "export type __self__ = \(primitive.tsPrimitiveType);"
  }

  guard let info = try? typeInfo(of: type) else {
    return "export type __self__ = unknown; /* !! runtime introspection failed */"
  }

  if info.kind == .enum {
    var enumTs = """
    export enum __self__ {
      \(info.cases.map(\.name).joined(separator: ",\n  ")),
    }
    """
    if derivingRootGlobalType {
      enumTs = identify(enumTs, sharedTypeName ?? "\(type)")
    }
    return enumTs
  }

  if info.genericTypes.count == 1, info.name.starts(with: "Array<"),
     let element = info.genericTypes.first as? TypescriptRepresentable.Type {
    return "export type __self__ = Array<\(unnest(derive(element, &named, depth + 1)))>"
  }

  let props = info.properties
  var ts = "export interface __self__ {\n"
  for prop in props {
    ts += "  \(prop.name)\(tsProp(prop.type, &named, depth + 1))"
  }
  ts += "}"

  if derivingRootGlobalType {
    ts = identify(ts, sharedTypeName ?? "\(type)")
  }

  return ts
}

func tsProp(
  _ type: Any.Type,
  _ named: inout [String: String],
  _ depth: Int,
  optional: Bool = false
) -> String {
  if let type = type as? TypescriptPrimitive.Type {
    return optional
      ? "?: " + type.tsPrimitiveType + ";\n"
      : ": " + type.tsPrimitiveType + ";\n"
  }

  if let info = try? typeInfo(of: type), info.kind == .optional {
    return tsProp(info.genericTypes[0], &named, depth, optional: true)
  }

  if let nested = type as? TypescriptRepresentable.Type {
    return "\(optional ? "?" : ""): \(unnest(derive(nested, &named, depth)));\n"
  }
  return ": unknown; /* !! runtime introspection failed */\n"
}

private func identify(_ ts: String, _ name: String) -> String {
  ts.replacingOccurrences(of: "__self__", with: name)
}

private func unnest(_ ts: String) -> String {
  ts
    .replacingOccurrences(of: "export interface __self__ ", with: "")
    .replacingOccurrences(of: "export type __self__ = ", with: "")
    .replacingOccurrences(of: "export type __self__ =", with: "")
    .replacingOccurrences(of: "\n", with: " ")
    .replacingOccurrences(of: "   ", with: " ")
}
