import Gertie

@testable import Api

extension UnlockRequest: RandomMocked {
  public static var mock: UnlockRequest {
    UnlockRequest(networkDecisionId: .init(), userDeviceId: .init())
  }

  public static var empty: UnlockRequest {
    UnlockRequest(networkDecisionId: .init(), userDeviceId: .init())
  }

  public static var random: UnlockRequest {
    UnlockRequest(networkDecisionId: .init(), userDeviceId: .init())
  }
}
