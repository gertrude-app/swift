import Foundation
import PairQL

/// in use: v2.0.0 - present
public struct CreateUnlockRequests_v2: Pair {
  public static var auth: ClientAuth = .user

  public struct Input: PairInput {
    /// NB: used to have a `time: Date` field, but removed as non-breaking
    /// change in 2.1.3, when we eliminated network_decisions table
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

    public init(
      blockedRequests: [CreateUnlockRequests_v2.Input.BlockedRequest],
      comment: String? = nil
    ) {
      self.blockedRequests = blockedRequests
      self.comment = comment
    }
  }
}
