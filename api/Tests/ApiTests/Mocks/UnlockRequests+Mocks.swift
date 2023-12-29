import Gertie

@testable import Api

extension UnlockRequest: RandomMocked {
  public static var mock: UnlockRequest {
    UnlockRequest(userDeviceId: .init(), appBundleId: "com.acme.widget")
  }

  public static var empty: UnlockRequest {
    UnlockRequest(userDeviceId: .init(), appBundleId: "")
  }

  public static var random: UnlockRequest {
    UnlockRequest(userDeviceId: .init(), appBundleId: "com.".random)
  }
}
