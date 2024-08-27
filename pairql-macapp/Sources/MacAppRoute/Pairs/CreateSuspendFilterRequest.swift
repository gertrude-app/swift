import PairQL

/// @deprecated, in use from v2.0.0 - v2.3.2
public struct CreateSuspendFilterRequest: Pair {
  public static let auth: ClientAuth = .user
  public typealias Input = CreateSuspendFilterRequest_v2.Input
}
