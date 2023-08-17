import Gertie
import PairQL

/// in use: v2.0.0 - present
public struct GetAccountStatus: Pair {
  public static var auth: ClientAuth = .user

  public struct Output: PairOutput {
    public let status: AdminAccountStatus

    public init(status: AdminAccountStatus) {
      self.status = status
    }
  }
}
