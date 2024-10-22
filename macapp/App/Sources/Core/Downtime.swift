import Foundation
import Gertie

public struct Downtime {
  public var window: PlainTimeWindow
  public var pausedUntil: Date?

  public init(window: PlainTimeWindow, pausedUntil: Date? = nil) {
    self.window = window
    self.pausedUntil = pausedUntil
  }
}

public extension Downtime {
  func isPaused(at date: Date = .init()) -> Bool {
    date < self.pausedUntil ?? .distantPast
  }

  func shouldBlock(at date: Date, in calendar: Calendar) -> Bool {
    guard !self.isPaused(at: date) else { return false }
    return self.window.contains(date, in: calendar)
  }
}

extension Downtime: Equatable, Sendable, Codable {}
