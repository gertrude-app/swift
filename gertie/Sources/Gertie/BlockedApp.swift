public struct BlockedApp {
  public var name: String
  public var bundleIds: [String]
  public var schedule: RuleSchedule?

  public init(name: String, bundleIds: [String], schedule: RuleSchedule? = nil) {
    self.bundleIds = bundleIds
    self.name = name
    self.schedule = schedule
  }
}

public extension BlockedApp {
  func blocks(bundleId: String, name: String) -> Bool {
    if name == self.name {
      return true
    } else {
      return self.bundleIds.contains(where: { $0.contains(bundleId) })
    }
  }
}

public extension Collection where Element == BlockedApp {
  func blocks(bundleId: String, name: String) -> Bool {
    self.contains { $0.blocks(bundleId: bundleId, name: name) }
  }
}

// conformances

extension BlockedApp: Equatable, Codable, Sendable, Hashable {}
