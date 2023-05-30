import PairQL

public struct RecentAppVersions: Pair {
  public static var auth: ClientAuth = .none
  public typealias Output = [String: String]
}
