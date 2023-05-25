import PairQL
import Shared

public struct GetUserData: Pair {
  public static var auth: ClientAuth = .user
  public typealias Output = UserData
}
