import Foundation
import PairQL

/// in use: v1.0.0 - present
public struct LogPodcastEvent: Pair {
  public static let auth: ClientAuth = .none

  public struct Input: PairInput {
    public var eventId: String
    public var kind: String
    public var label: String
    public var detail: String?
    public var installId: UUID?
    public var deviceType: String
    public var appVersion: String
    public var iosVersion: String

    public init(
      eventId: String,
      kind: String,
      label: String,
      detail: String? = nil,
      installId: UUID? = nil,
      deviceType: String,
      appVersion: String,
      iosVersion: String,
    ) {
      self.eventId = eventId
      self.kind = kind
      self.label = label
      self.detail = detail
      self.installId = installId
      self.deviceType = deviceType
      self.appVersion = appVersion
      self.iosVersion = iosVersion
    }
  }

  public typealias Output = Infallible
}
