import Foundation
import PairQL

public struct CreateUnlockRequests_v2: Pair {
  public static var auth: ClientAuth = .user

  public struct Input: PairInput {
    public struct BlockedRequest: PairNestable {
      public let time: Date
      public let bundleId: String
      public let url: String?
      public let hostname: String?
      public let ipAddress: String?

      public init(
        time: Date,
        bundleId: String,
        url: String? = nil,
        hostname: String? = nil,
        ipAddress: String? = nil
      ) {
        self.time = time
        self.bundleId = bundleId
        self.url = url
        self.hostname = hostname
        self.ipAddress = ipAddress
      }
    }

    public let blockedRequests: [BlockedRequest]
    public let comment: String?

    public init(
      blockedRequests: [CreateUnlockRequests_v2.Input.BlockedRequest],
      comment: String? = nil
    ) {
      self.blockedRequests = blockedRequests
      self.comment = comment
    }
  }
}
