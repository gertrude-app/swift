public enum BlockRule {
  // WARNING: all changes must be carefully synced w/ typescript below!
  case bundleIdContains(value: String)
  case urlContains(value: String)
  case hostnameContains(value: String)
  case hostnameEquals(value: String)
  case hostnameEndsWith(value: String)
  case targetContains(value: String) // "target" = url ?? hostname
  case flowTypeIs(value: FlowType)
  indirect case both(a: BlockRule, b: BlockRule)
  indirect case unless(rule: BlockRule, negatedBy: [BlockRule])
}

public extension BlockRule {
  static var typescriptAlias: String {
    """
      | { case: 'bundleIdContains'; value: string }
      | { case: 'urlContains'; value: string }
      | { case: 'hostnameContains'; value: string }
      | { case: 'hostnameEquals'; value: string }
      | { case: 'hostnameEndsWith'; value: string }
      | { case: 'targetContains'; value: string }
      | { case: 'flowTypeIs'; value: 'browser' | 'socket' }
      | { case: 'both'; a: BlockRule; b: BlockRule }
      | { case: 'unless'; rule: BlockRule; negatedBy: BlockRule[] }
    """
  }
}

// conformances

extension BlockRule: Equatable, Codable, Sendable, Hashable {}
