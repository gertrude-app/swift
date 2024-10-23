import Foundation

public struct FilterLogs {
  public var bundleIds: [String: Int]
  public var events: [Event: Int]

  public init(bundleIds: [String: Int] = [:], events: [Event: Int] = [:]) {
    self.bundleIds = bundleIds
    self.events = events
  }

  public struct Event {
    public var id: String
    public var detail: String?

    public init(id: String, detail: String? = nil) {
      self.id = id
      self.detail = detail
    }
  }
}

public extension FilterLogs {
  mutating func log(event: Event) {
    for (existing, count) in self.events {
      if existing.id == event.id, existing.detail == event.detail {
        self.events[existing] = count + 1
        return
      }
    }
    self.events[event] = 1
  }

  func count() -> Int {
    self.events.values.reduce(0, +) + self.bundleIds.values.reduce(0, +)
  }
}

// extensions

extension FilterLogs: Equatable, Codable, Sendable {}
extension FilterLogs.Event: Equatable, Hashable, Codable, Sendable {}
