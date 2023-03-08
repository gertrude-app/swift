public struct CodeGen {
  let config: Config

  public init(config: Config = .init()) {
    self.config = config
  }

  public func declaration(for type: Any.Type, as name: String? = nil) throws -> String {
    let root = try Node(from: type)
    return "export type \(name ?? "\(type)") = \(root.declaration(.init(config: config)))"
  }
}
