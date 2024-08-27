import Foundation
import PairQL

/// in use: v2.4.0 - present
public struct CreateSuspendFilterRequest_v2: Pair {
  public static let auth: ClientAuth = .user

  public struct Input: PairInput {
    public var duration: Int
    public var comment: String?

    public init(duration: Int, comment: String?) {
      self.duration = duration
      self.comment = comment
    }
  }

  public typealias Output = UUID
}
