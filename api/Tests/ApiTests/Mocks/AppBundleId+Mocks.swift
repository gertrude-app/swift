import Gertie

@testable import Api

extension AppBundleId: RandomMocked {
  public static var mock: AppBundleId {
    AppBundleId(identifiedAppId: .init(), bundleId: "@mock bundleId")
  }

  public static var empty: AppBundleId {
    AppBundleId(identifiedAppId: .init(), bundleId: "")
  }

  public static var random: AppBundleId {
    AppBundleId(identifiedAppId: .init(), bundleId: "@random".random)
  }
}
