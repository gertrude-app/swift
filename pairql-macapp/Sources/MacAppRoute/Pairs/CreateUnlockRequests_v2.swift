import Foundation
import PairQL

/// deprecated: v2.0.0 - v2.3.2
/// remove when v2.3.4 is MSV
public struct CreateUnlockRequests_v2: Pair {
  public static let auth: ClientAuth = .user
  public typealias Input = CreateUnlockRequests_v3.Input
}
