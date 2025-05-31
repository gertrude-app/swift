import Foundation
import Gertie
import PairQL
import TaggedTime

/// in use: v1.5.0 - present
public struct PollFilterSuspensionDecision: Pair {
  public static let auth: ClientAuth = .child
  public typealias Input = UUID

  public enum Output: PairOutput {
    case pending
    case denied(parentComment: String?)
    case accepted(duration: Seconds<Int>, parentComment: String?)
    case notFound
  }
}

extension RequestStatus: @retroactive PairOutput {}
