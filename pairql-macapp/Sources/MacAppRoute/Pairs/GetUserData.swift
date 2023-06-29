import PairQL
import Gertie

public struct GetUserData: Pair {
  public static var auth: ClientAuth = .user
  public typealias Output = UserData
}
