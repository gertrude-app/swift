import PairQL
import Gertie

extension ReleaseChannel: PairInput {}

public struct LatestAppVersion: Pair {
  public static var auth: ClientAuth = .user
  public typealias Output = String
  public typealias Input = ReleaseChannel
}
