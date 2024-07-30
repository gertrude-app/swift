import Foundation
import PairQL

/// in use: v2.2.0 - present
public struct LogSecurityEvent: Pair {
  public static let auth: ClientAuth = .user

  public struct Input: PairInput {
    public var deviceId: UUID
    public var event: String
    public var detail: String?

    public init(deviceId: UUID, event: String, detail: String? = nil) {
      self.deviceId = deviceId
      self.event = event
      self.detail = detail
    }
  }
}
