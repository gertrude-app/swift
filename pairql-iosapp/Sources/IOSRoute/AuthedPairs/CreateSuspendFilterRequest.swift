import Foundation
import PairQL
import TaggedTime

/// in use: v1.5.0 - present
public struct CreateSuspendFilterRequest: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var duration: Seconds<Int>
    public var comment: String?

    public init(duration: Seconds<Int>, comment: String? = nil) {
      self.duration = duration
      self.comment = comment
    }
  }

  public typealias Output = UUID
}

public extension CreateSuspendFilterRequest.Input {
  init(durationInSeconds: Int, comment: String?) {
    self.duration = Seconds(durationInSeconds)
    self.comment = comment
  }
}
