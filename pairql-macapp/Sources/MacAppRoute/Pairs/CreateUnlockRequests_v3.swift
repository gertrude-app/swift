import Foundation
import PairQL

/// in use: v2.4.0 - present
public struct CreateUnlockRequests_v3: Pair {
  public static let auth: ClientAuth = .user

  public struct Input: PairInput {
    public struct BlockedRequest: PairNestable {
      public let bundleId: String
      public let url: String?
      public let hostname: String?
      public let ipAddress: String?

      public init(
        bundleId: String,
        url: String? = nil,
        hostname: String? = nil,
        ipAddress: String? = nil
      ) {
        self.bundleId = bundleId
        self.url = url
        self.hostname = hostname
        self.ipAddress = ipAddress
      }
    }

    public let blockedRequests: [BlockedRequest]
    public let comment: String?

    public init(blockedRequests: [BlockedRequest], comment: String? = nil) {
      self.blockedRequests = blockedRequests
      self.comment = comment
    }
  }

  public typealias Output = [UUID]
}
