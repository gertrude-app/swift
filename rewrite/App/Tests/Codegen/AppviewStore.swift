import Foundation
import TypeScript

struct AppviewStore {
  struct SwiftType {
    let type: Any.Type
    let alias: String?

    init(_ type: Any.Type, as alias: String? = nil) {
      self.type = type
      self.alias = alias
    }
  }

  let path: String
  let types: [SwiftType]
  let aliases: [String: String]

  init(
    at path: String,
    generating types: [SwiftType],
    aliasing aliases: [String: String] = [:]
  ) {
    self.path = path
    self.types = types
    self.aliases = aliases
  }
}

// extensions

extension AppviewStore: CodeGenerator {
  var decls: [String] {
    get throws {
      let ts = CodeGen(config: .init(compact: true, aliasing: aliases))
      return try types.map { try ts.declaration(for: $0.type, as: $0.alias) }
    }
  }

  func write() throws {
    let url = URL(fileURLWithPath: "/Users/jared/gertie/web/appviews/src/\(path)")
    let file = String(data: try Data(contentsOf: url), encoding: .utf8)!
    let lines = file.components(separatedBy: "\n")

    var updated: [String] = []
    var inCodegen = false
    for line in lines {
      if line == "// begin codegen" {
        inCodegen = true
        updated.append(line)
        updated.append(try decls.joined(separator: "\n\n"))
      } else if line.contains("// end codegen") {
        inCodegen = false
        updated.append(line)
      } else if !inCodegen {
        updated.append(line)
      }
    }

    try updated.joined(separator: "\n")
      .data(using: .utf8)!
      .write(to: url)
  }
}
