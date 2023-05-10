import Foundation
import TypeScript

struct TypeScriptEnum {
  let name: String
  let types: [Any.Type]
}

// extensions

extension TypeScriptEnum: CodeGenerator {
  var path: String {
    "/Users/jared/gertie/swift/rewrite/App/Sources/App/Generated/\(name)+Codable.swift"
  }

  func write() throws {
    let decls = try types.map {
      let enumType = try EnumType(from: $0)
      if ProcessInfo.processInfo.environment["CODEGEN_UNIMPLEMENTED"] != nil {
        return enumType.unimplementedConformance()
      } else {
        return enumType.codableConformance()
      }
    }

    let fileBody = decls.joined(separator: "\n\n")
    var headerLines = [
      "// auto-generated, do not edit",
      "import Foundation",
    ]

    if fileBody.contains("ReleaseChannel") {
      headerLines.append("import Shared")
    }

    let header = headerLines.joined(separator: "\n")
    let file = header + "\n\n" + decls.joined(separator: "\n\n")
    try file.data(using: .utf8)!.write(to: URL(fileURLWithPath: path))
  }
}
