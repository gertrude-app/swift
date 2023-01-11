import Foundation
import PairQL

public struct CreateUnlockRequests: Pair {
  public static var auth: ClientAuth = .user

  public typealias Input = [UnlockRequestInput]

  public struct UnlockRequestInput: PairInput {
    public var networkDecisionId: UUID
    public var comment: String?

    public init(networkDecisionId: UUID, comment: String? = nil) {
      self.networkDecisionId = networkDecisionId
      self.comment = comment
    }
  }
}
