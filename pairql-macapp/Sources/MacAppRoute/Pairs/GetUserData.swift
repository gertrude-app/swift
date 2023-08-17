import Gertie
import PairQL

/// in use: v2.0.0 - present
public struct GetUserData: Pair {
  public static var auth: ClientAuth = .user
  public typealias Output = UserData
}
