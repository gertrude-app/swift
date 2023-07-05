import Foundation
import PairQL

public struct LogInterestingEvent: Pair {
  public static var auth: ClientAuth = .none

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
