import Foundation
import PairQL

/// in use: v2.0.0 - present
public struct LogInterestingEvent: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var eventId: String
    public var kind: String
    public var deviceId: UUID?
    public var detail: String?

    public init(
      eventId: String,
      kind: String,
      deviceId: UUID? = nil,
      detail: String? = nil
    ) {
      self.eventId = eventId
      self.kind = kind
      self.deviceId = deviceId
      self.detail = detail
    }
  }
}
