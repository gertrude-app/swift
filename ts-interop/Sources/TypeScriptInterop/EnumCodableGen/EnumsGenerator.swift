import Foundation

public extension EnumCodableGen {
  struct EnumsGenerator {
    public var path: String
    public var types: [(Any.Type, Bool)]
    public var imports: [String: String] = [:]
    public var replacements: [String: String] = [:]
    public var formatterBin: String?

    public init(
      path: String,
      types: [(Any.Type, Bool)],
      imports: [String: String] = [:],
      replacements: [String: String] = [:],
      formatterBin: String? = nil,
    ) {
      self.path = path
      self.types = types
      self.imports = imports
      self.replacements = replacements
      self.formatterBin = formatterBin
    }
  }
}

// extensions

extension EnumCodableGen.EnumsGenerator: CodeGenerator {
  public func write() throws {
    let decls = try self.types.map { type, is_public in
      let enumType = try EnumCodableGen.EnumType(from: type)
      if ProcessInfo.processInfo.environment["CODEGEN_UNIMPLEMENTED"] != nil {
        return enumType.unimplementedConformance()
      } else {
        return enumType.codableConformance(public: is_public)
      }
    }

    let fileBody = decls.joined(separator: "\n\n")
    var headerLines = [
      "// auto-generated, do not edit",
      "import Foundation",
    ]

    for (sentinalTypeName, requiredModule) in imports {
      if fileBody.contains(sentinalTypeName) {
        headerLines.append("import \(requiredModule)")
      }
    }

    let header = headerLines.joined(separator: "\n")
    var file = header + "\n\n" + decls.joined(separator: "\n\n")

    for (find, replace) in replacements {
      file = file.replacingOccurrences(of: find, with: replace)
    }

    try file.data(using: .utf8)!.write(to: URL(fileURLWithPath: path))
  }

  public func format() throws {
    guard let bin = formatterBin else {
      return
    }

    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: bin)
    proc.arguments = [path]
    try proc.run()
  }
}
