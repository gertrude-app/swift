import Foundation

public struct BlockedApp {
  public var identifier: String
  public var schedule: RuleSchedule?

  public init(identifier: String, schedule: RuleSchedule? = nil) {
    self.identifier = identifier
    self.schedule = schedule
  }
}

public extension BlockedApp {
  func blocks(app: RunningApp, at date: Date, in calendar: Calendar = .current) -> Bool {
    if self.schedule.map({ $0.active(at: date, in: calendar) }) == .some(false) {
      // if it has a schedule, and it's not active, we know it isn't blocked
      false
    } else if app.localizedName == self.identifier {
      true
    } else if app.bundleName == self.identifier {
      true
    } else if app.bundleId == self.identifier {
      true
    } else if self.identifier.contains("."), app.bundleId.contains(self.identifier) {
      true
    } else {
      false
    }
  }
}

public extension Collection<BlockedApp> {
  func blocks(app: RunningApp, at date: Date, in calendar: Calendar = .current) -> Bool {
    self.contains { $0.blocks(app: app, at: date, in: calendar) }
  }
}

// conformances

extension BlockedApp: Equatable, Codable, Sendable, Hashable {}
