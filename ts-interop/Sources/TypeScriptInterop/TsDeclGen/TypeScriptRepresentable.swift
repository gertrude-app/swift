import Foundation

protocol TypeScriptRepresentable {
  func declaration(_ ctx: Context) -> String
}

extension Node: TypeScriptRepresentable {
  func declaration(_ ctx: Context = .init())
    -> String {
    if let alias = ctx.config.alias(for: self) {
      return alias
    }
    switch self {
    case .array(let element, _):
      let decl = element.declaration(ctx)
      return decl.contains(" ") ? "Array<\(decl)>" : "\(decl)[]"

    case .object(let props, let type):
      if let alias = ctx.config.alias(for: type) {
        return alias
      }
      var decl = "{\(ctx.newLine)"
      decl += ctx.compact(" ", or: (ctx++).indent)
      decl += props.declaration(ctx++)
      decl += ctx.compact(" }", or: "\n\(ctx.indent)}")
      return decl

    case .primitive(let primitive):
      return primitive.declaration(ctx)

    case .record(let value):
      let decl = value.declaration(ctx)
      return "{ [key: string]: \(decl) }"

    case .stringUnion(let members, _):
      return members.map { "'\($0)'" }.joined(separator: " | ")

    case .objectUnion(let members, _):
      return members.map { $0.declaration(ctx) }.joined(separator: " | ")
    }
  }
}

extension Array where Element == Node.Property {
  func declaration(_ ctx: Context) -> String {
    let props = map { prop in prop.declaration(ctx) }
    return props.joined(separator: ctx.compact("; ", or: ";\n\(ctx.indent)")) + ";"
  }
}

extension Node.Property: TypeScriptRepresentable {
  func unindentedLhs(_ ctx: Context) -> String {
    let opt = optional ? "?" : ""
    let readonly = readonly && ctx.config.letsReadOnly ? "readonly " : ""
    return "\(readonly)\(name)\(opt): "
  }

  func declaration(_ ctx: Context) -> String {
    let propValue = ctx.config.alias(for: value) ?? value.declaration(ctx)
    return "\(self.unindentedLhs(ctx))\(propValue)"
  }
}

extension Node.ObjectUnionMember: TypeScriptRepresentable {
  func declaration(_ ctx: Context) -> String {
    var decl = "{\(ctx.newLine)"
    decl += ctx.compact(" ", or: (ctx++).indent)
    decl += "case: '\(caseName)';"
    for value in associatedValues {
      decl += ctx.compact(" ", or: "\n  \(ctx.indent)")
      decl += value.declaration(ctx++) + ";"
    }
    decl += ctx.compact(" }", or: "\n\(ctx.indent)}")
    return decl
  }
}

extension Node.Primitive: TypeScriptRepresentable {
  func declaration(_ ctx: Context) -> String {
    switch self {
    case .boolean:
      return ctx.config.alias(for: Bool.self) ?? "boolean"
    case .date:
      return ctx.config.alias(for: Date.self) ?? "Date"
    case .uuid:
      return ctx.config.alias(for: UUID.self) ?? "UUID"
    case .null:
      return "null"
    case .number(let type):
      return ctx.config.alias(for: type) ?? "number"
    case .string:
      return ctx.config.alias(for: String.self) ?? "string"
    case .void:
      return ctx.config.alias(for: Void.self) ?? "void"
    case .never:
      return ctx.config.alias(for: Never.self) ?? "never"
    case .stringLiteral(let string):
      return "'\(string)'"
    }
  }
}
