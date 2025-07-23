import Foundation
import GertieIOS
import PairQL

/// testflight: v1.4.0 - present
public struct ConnectedRules: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var vendorId: UUID
    public var deviceType: String
    public var appVersion: String
    public var iosVersion: String

    public init(
      vendorId: UUID,
      deviceType: String,
      appVersion: String,
      iosVersion: String
    ) {
      self.vendorId = vendorId
      self.deviceType = deviceType
      self.appVersion = appVersion
      self.iosVersion = iosVersion
    }
  }

  public struct Output: PairOutput {
    public var blockRules: [BlockRule]
    public var webPolicy: WebContentFilterPolicy

    public init(blockRules: [BlockRule], webPolicy: WebContentFilterPolicy) {
      self.blockRules = blockRules
      self.webPolicy = webPolicy
    }
  }
}
