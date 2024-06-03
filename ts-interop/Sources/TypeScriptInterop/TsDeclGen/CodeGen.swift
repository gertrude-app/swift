public struct CodeGen {
  let config: Config

  public init(config: Config = .init()) {
    self.config = config
  }

  public func declaration(for type: Any.Type, as name: String? = nil) throws -> String {
    let node = try Node(from: type)
    let decl = self.config.alias(for: type) ?? node.declaration(.init(config: self.config))
    if case .object = node, decl.contains(" ") || decl.contains("\n") {
      return "export interface \(name ?? "\(type)") \(decl)"
    } else {
      return "export type \(name ?? "\(type)") = \(decl)"
    }
  }
}

// TODO: rename...
public protocol TypeScriptAliased {
  static var typescriptAlias: String { get }
}
