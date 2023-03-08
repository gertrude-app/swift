public struct CodeGen {
  let config: Config

  public init(config: Config = .init()) {
    self.config = config
  }

  public func declaration(for type: Any.Type) throws -> String {
    let root = try Node(from: type)
    return "export type \(type) = \(root.declaration(.init(config: config)))"
  }
}
