struct CodeGen {
  func declaration(for type: Any.Type) throws -> String {
    let root = try Node(from: type)
    return "export interface \(type) \(ts(for: root, depth: 0))"
  }

  func ts(for node: Node, depth: Int) -> String {
    switch node {

    case .array(let element):
      return "\(ts(for: element, depth: depth + 1))[]"

    case .object(let props):
      var decl = "{\n"
      for prop in props {
        let opt = prop.optional ? "?" : ""
        let readonly = prop.readonly ? "readonly " : ""
        let value = ts(for: prop.value, depth: depth + 1)
        decl += "\(indent(depth + 1))\(readonly)\(prop.name)\(opt): \(value);\n"
      }
      decl += "\(indent(depth))}"
      return decl

    case .primitive(let primitive):
      switch primitive {
      case .boolean:
        return "boolean"
      case .null:
        return "boolean"
      case .number:
        return "number"
      case .string:
        return "string"
      case .stringLiteral(let string):
        return "'\(string)'"
      }

    case .tuple(let members):
      return "[\(members.map { ts(for: $0.value, depth: depth + 1) }.joined(separator: ", "))]"

    case .union(let members):
      return members.map { ts(for: $0, depth: depth + 1) }.joined(separator: " | ")
    }
  }
}

func indent(_ depth: Int) -> String {
  String(repeating: " ", count: depth * 2)
}
