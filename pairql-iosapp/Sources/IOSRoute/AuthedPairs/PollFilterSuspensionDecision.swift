import Foundation
import Gertie
import PairQL

/// in use: v1.5.0 - present
public struct PollFilterSuspensionDecision: Pair {
  public static let auth: ClientAuth = .child
  public typealias Input = UUID
  public typealias Output = RequestStatus
}

extension RequestStatus: @retroactive PairOutput {}
