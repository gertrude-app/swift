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

// conformances

extension BlockedApp: Equatable, Codable, Sendable, Hashable {}
