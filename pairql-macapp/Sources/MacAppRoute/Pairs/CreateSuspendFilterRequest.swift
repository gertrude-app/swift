import PairQL

/// in use: v2.0.0 - present
public struct CreateSuspendFilterRequest: Pair {
  public static let auth: ClientAuth = .user

  public struct Input: PairInput {
    public var duration: Int
    public var comment: String?

    public init(duration: Int, comment: String?) {
      self.duration = duration
      self.comment = comment
    }
  }
}
