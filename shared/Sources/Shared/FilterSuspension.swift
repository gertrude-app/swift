import Foundation
import TaggedTime

public struct FilterSuspension: Equatable, Codable {
  public var scope: AppScope
  public var duration: Seconds<Int>
  public let expiresAt: Date

  public var isActive: Bool {
    expiresAt > Date()
  }

  public init(scope: AppScope, duration: Seconds<Int>) {
    self.scope = scope
    self.duration = duration
    expiresAt = Date(timeIntervalSinceNow: .init(duration.rawValue))
  }
}
