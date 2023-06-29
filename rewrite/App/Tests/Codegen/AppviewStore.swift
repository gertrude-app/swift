import Foundation
import TypeScriptInterop

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
  let namedTypes: [SwiftType]
  let types: [SwiftType]
  let localAliases: [(Any.Type, String)]
  let globalAliases: [(Any.Type, String)]

  init(
    at path: String,
    namedTypes: [SwiftType] = [],
    types: [SwiftType] = [],
    localAliases: [(Any.Type, String)] = [],
    globalAliases: [(Any.Type, String)] = []
  ) {
    self.path = path
    self.namedTypes = namedTypes
    self.types = types
    self.localAliases = localAliases
    self.globalAliases = globalAliases
  }
}

// extensions

extension AppviewStore: CodeGenerator {
  var decls: [String] {
    get throws {
      // generate named/extracted decls without all aliases
      var config = Config(
        compact: true,
        aliasing: globalAliases.map { .init($0, as: $1) } + [.init(Date.self, as: "ISODateString")]
      )
      let namedDecls = try namedTypes.map {
        let ts = CodeGen(config: config)
        let decl = try ts.declaration(for: $0.type, as: $0.alias)
        config.addAlias(.init($0.type, as: $0.alias))
        return decl
      }

      // generate rest of decls using shared aliases
      let ts = CodeGen(config: .init(
        compact: true,
        aliasing: localAliases.map { .init($0, as: $1) } + [.init(Date.self, as: "ISODateString")]
      ))
      let aliasedDecls = try types.map { try ts.declaration(for: $0.type, as: $0.alias) }

      return namedDecls + aliasedDecls
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
