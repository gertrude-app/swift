import PairQL
import Gertie

public struct GetAccountStatus: Pair {
  public static var auth: ClientAuth = .user

  public struct Output: PairOutput {
    public let status: AdminAccountStatus

    public init(status: AdminAccountStatus) {
      self.status = status
    }
  }
}
