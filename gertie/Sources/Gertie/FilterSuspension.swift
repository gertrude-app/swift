import Foundation
import TaggedTime

public struct FilterSuspension: Equatable, Codable, Sendable {
  public var scope: AppScope
  public var duration: Seconds<Int>
  public let expiresAt: Date

  public var isActive: Bool {
    expiresAt > Date()
  }

  public init(scope: AppScope, duration: Seconds<Int>, now: Date = Date()) {
    self.scope = scope
    self.duration = duration
    expiresAt = now.advanced(by: Double(duration.rawValue))
  }
}