public struct Config {
  public struct Alias {
    public let type: AnyType
    public let alias: String?

    public init(_ type: Any.Type, as alias: String? = nil) {
      self.type = .init(type)
      self.alias = alias
    }
  }

  public var compact: Bool
  public var letsReadOnly: Bool
  public var aliases: [AnyType: String?]

  public init(
    compact: Bool = false,
    letsReadOnly: Bool = false,
    aliasing aliases: [Alias] = []
  ) {
    self.compact = compact
    self.letsReadOnly = letsReadOnly
    self.aliases = .init(uniqueKeysWithValues: aliases.map { ($0.type, $0.alias) })
  }

  public mutating func addAlias(_ alias: Alias) {
    self.aliases[alias.type] = alias.alias
  }

  public func alias(for node: Node) -> String? {
    self.alias(for: node.anyType)
  }

  public func alias(for anyType: AnyType) -> String? {
    self.alias(for: anyType.type)
  }

  public func alias(for type: Any.Type) -> String? {
    switch self.aliases[.init(type)] {
    case .some(.some(let alias)):
      // prefer explicit alias over conformance
      return alias
    case .some(.none):
      if let aliased = type as? TypeScriptAliased.Type {
        return aliased.typescriptAlias
      } else {
        return AnyType(type).name
      }
    case .none:
      return (type as? TypeScriptAliased.Type)?.typescriptAlias
    }
  }
}
