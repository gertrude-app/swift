import Gertie
import PairQL

/// deprecated: v2.0.0 - v2.0.3
/// remove when v2.0.4 is MSV
public struct GetAccountStatus: Pair {
  public static var auth: ClientAuth = .user

  public struct Output: PairOutput {
    public let status: AdminAccountStatus

    public init(status: AdminAccountStatus) {
      self.status = status
    }
  }
}
