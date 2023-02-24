struct CodeGen {
  let config: Config

  init(config: Config = .init()) {
    self.config = config
  }

  func declaration(for type: Any.Type) throws -> String {
    let root = try Node(from: type)
    return "export interface \(type) \(root.declaration(.init(config: config)))"
  }
}
