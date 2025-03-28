import Foundation
import GertieIOS
import PairQL

/// in use: v1.5.0 - present
public struct BlockRules_v3: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var vendorId: UUID
    public var version: String
    public var deviceType: String
    public var appVersion: String
    public var iosVersion: String
  }

  public typealias Output = [BlockRule]
}
