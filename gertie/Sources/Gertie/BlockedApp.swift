public struct BlockedApp {
  public var identifier: String
  public var schedule: RuleSchedule?

  public init(identifier: String, schedule: RuleSchedule? = nil) {
    self.identifier = identifier
    self.schedule = schedule
  }
}

public extension BlockedApp {
  func blocks(app: RunningApp) -> Bool {
    if app.localizedName == self.identifier {
      return true
    } else if app.bundleName == self.identifier {
      return true
    } else if app.bundleId == self.identifier {
      return true
    } else if self.identifier.contains("."), app.bundleId.contains(self.identifier) {
      return true
    } else {
      return false
    }
  }
}

public extension Collection where Element == BlockedApp {
  func blocks(app: RunningApp) -> Bool {
    self.contains { $0.blocks(app: app) }
  }
}

// conformances

extension BlockedApp: Equatable, Codable, Sendable, Hashable {}
