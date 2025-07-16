public struct CodeGen {
  let config: Config

  public init(config: Config = .init()) {
    self.config = config
  }

  public func declaration(for type: Any.Type, as name: String? = nil) throws -> String {
    if let alias = self.config.alias(for: type) {
      return "export type \(name ?? "\(type)") = \(alias)"
    }

    let node = try Node(from: type, config: self.config)
    let decl = node.declaration(.init(config: self.config))
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
