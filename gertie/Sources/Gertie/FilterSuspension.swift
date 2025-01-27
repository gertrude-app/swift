import Foundation
import TaggedTime
import XCore

public struct FilterSuspension: Equatable, Codable, Sendable {
  public var scope: AppScope
  public var duration: Seconds<Int>
  public let expiresAt: Date

  public var isActive: Bool {
    self.expiresAt > Date()
  }

  public init(scope: AppScope, duration: Seconds<Int>, now: Date = Date()) {
    self.scope = scope
    self.duration = duration
    self.expiresAt = now.advanced(by: Double(duration.rawValue))
  }

  public init(scope: AppScope, duration: Seconds<Int>, expiresAt: Date) {
    self.scope = scope
    self.duration = duration
    self.expiresAt = expiresAt
  }
}

public extension FilterSuspension {
  func relativeExpiration(from now: Date = Date()) -> String {
    now.timeRemaining(until: self.expiresAt)
  }
}
