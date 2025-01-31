import Gertie

@testable import Api

extension UnlockRequest: RandomMocked {
  public static var mock: UnlockRequest {
    UnlockRequest(computerUserId: .init(), appBundleId: "com.acme.widget")
  }

  public static var empty: UnlockRequest {
    UnlockRequest(computerUserId: .init(), appBundleId: "")
  }

  public static var random: UnlockRequest {
    UnlockRequest(computerUserId: .init(), appBundleId: "com.".random)
  }
}
