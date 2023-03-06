struct Config {
  let compact: Bool

  init(compact: Bool = false) {
    self.compact = compact
  }
}

struct Context {
  let config: Config
  let depth: Int

  init(config: Config = .init(), depth: Int = 0) {
    self.config = config
    self.depth = depth
  }

  var inline: Context {
    Context(config: config, depth: depth)
  }

  var indent: String {
    config.compact ? " " : String(repeating: " ", count: depth * 2)
  }

  var newLine: String {
    config.compact ? "" : "\n"
  }

  var indentedNewLine: String {
    config.compact ? "" : "\n\(indent)"
  }

  func compact(_ compact: String, or expanded: String) -> String {
    config.compact ? compact : expanded
  }
}

postfix operator ++

extension Context {
  static postfix func ++ (lhs: Context) -> Context {
    Context(config: lhs.config, depth: lhs.depth + 1)
  }
}

protocol TypeScriptRepresentable {
  func declaration(_ ctx: Context) -> String
}

extension Node: TypeScriptRepresentable {
  func declaration(_ ctx: Context = .init())
    -> String {
    switch self {

    case .array(let element):
      let decl = element.declaration(ctx)
      return decl.contains(" ") ? "Array<\(decl)>" : "\(decl)[]"

    case .object(let props):
      var decl = "{\(ctx.newLine)"
      decl += ctx.compact(" ", or: (ctx++).indent)
      decl += props.declaration(ctx++)
      decl += ctx.compact(" }", or: "\n\(ctx.indent)}")
      return decl

    case .primitive(let primitive):
      return primitive.declaration(ctx)

    case .union(let members):
      return members.declaration(ctx)
    }
  }
}

extension Array where Element == Node.Property {
  func declaration(_ ctx: Context) -> String {
    let props = map { prop in prop.declaration(ctx) }
    return props.joined(separator: ctx.compact("; ", or: ";\n\(ctx.indent)")) + ";"
  }
}

extension Array where Element == Node {
  func declaration(_ ctx: Context) -> String {
    let members = map { $0.declaration(ctx) }
    return members.joined(separator: " | ")
  }
}

extension Node.Property: TypeScriptRepresentable {
  var unindentedLhs: String {
    let opt = optional ? "?" : ""
    let readonly = readonly ? "readonly " : ""
    return "\(readonly)\(name)\(opt): "
  }

  func declaration(_ ctx: Context) -> String {
    let propValue = value.declaration(ctx)
    return "\(unindentedLhs)\(propValue)"
  }
}

extension Node.Primitive: TypeScriptRepresentable {
  func declaration(_ ctx: Context) -> String {
    switch self {
    case .boolean:
      return "boolean"
    case .null:
      return "boolean"
    case .number:
      return "number"
    case .string:
      return "string"
    case .void:
      return "void"
    case .never:
      return "never"
    case .stringLiteral(let string):
      return "'\(string)'"
    }
  }
}
