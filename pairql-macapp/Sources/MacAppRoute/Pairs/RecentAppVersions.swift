import PairQL

/// in use: v2.0.0 - present
public struct RecentAppVersions: Pair {
  public static var auth: ClientAuth = .none
  public typealias Output = [String: String]
}
