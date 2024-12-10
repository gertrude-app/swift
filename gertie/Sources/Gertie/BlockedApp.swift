public struct BlockedApp {
  public var bundleId: String
  public var displayName: String
  public var schedule: RuleSchedule?

  public init(bundleId: String, displayName: String, schedule: RuleSchedule? = nil) {
    self.bundleId = bundleId
    self.displayName = displayName
    self.schedule = schedule
  }
}

public extension BlockedApp {
  func blocks(bundleId: String, displayName: String) -> Bool {
    self.bundleId.contains(bundleId) || displayName == self.displayName
  }
}

public extension Collection where Element == BlockedApp {
  func blocks(bundleId: String, displayName: String) -> Bool {
    self.contains { $0.blocks(bundleId: bundleId, displayName: displayName) }
  }
}

// conformances

extension BlockedApp: Equatable, Codable, Sendable, Hashable {}
