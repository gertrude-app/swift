import Foundation
import TypeScript

struct TypeScriptEnum {
  let module: String
  let types: [Any.Type]
}

// extensions

extension TypeScriptEnum: CodeGenerator {
  var path: String {
    "/Users/jared/gertie/swift/rewrite/App/Sources/\(module)/\(module)+Codable.swift"
  }

  func write() throws {
    let url = URL(fileURLWithPath: path)
    let header = """
    // auto-generated, do not edit
    import TypeScript
    """
    let decls = try types.map { try EnumType(from: $0).codableConformance }
    let file = header + "\n\n" + decls.joined(separator: "\n\n")
    try file.data(using: .utf8)!.write(to: url)
  }
}
