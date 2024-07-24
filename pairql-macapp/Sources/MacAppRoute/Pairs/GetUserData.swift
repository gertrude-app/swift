import Gertie
import PairQL

/// deprecated: v2.0.0 - v2.0.3
/// remove when v2.0.4 is MSV
public struct GetUserData: Pair {
  public static let auth: ClientAuth = .user
  public typealias Output = UserData
}
