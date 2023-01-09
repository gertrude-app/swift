import PairQL

public struct CreateSuspendFilterRequest: Pair {
  public static var auth: ClientAuth = .user

  public struct Input: PairInput {
    public var duration: Int
    public var comment: String?

    public init(duration: Int, comment: String?) {
      self.duration = duration
      self.comment = comment
    }
  }
}
