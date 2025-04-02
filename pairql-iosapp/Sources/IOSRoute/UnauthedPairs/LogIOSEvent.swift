import Foundation
import PairQL

/// in use: v1.0.0 - present
public struct LogIOSEvent: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var eventId: String
    public var kind: String
    public var deviceType: String // "iPhone" | "iPad"
    public var iOSVersion: String // "18.0.1"
    public var vendorId: UUID?
    public var detail: String?

    public init(
      eventId: String,
      kind: String,
      deviceType: String,
      iOSVersion: String,
      vendorId: UUID? = nil,
      detail: String? = nil
    ) {
      self.eventId = eventId
      self.kind = kind
      self.deviceType = deviceType
      self.iOSVersion = iOSVersion
      self.vendorId = vendorId
      self.detail = detail
    }
  }

  public typealias Output = Infallible
}
