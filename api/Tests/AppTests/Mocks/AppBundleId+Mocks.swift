import DuetMock

@testable import App

extension AppBundleId {
  static var mock: AppBundleId {
    AppBundleId(identifiedAppId: .init(), bundleId: "@mock bundleId")
  }

  static var empty: AppBundleId {
    AppBundleId(identifiedAppId: .init(), bundleId: "")
  }

  static var random: AppBundleId {
    AppBundleId(identifiedAppId: .init(), bundleId: "@random".random)
  }
}
