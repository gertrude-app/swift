import Core
import Dependencies
import Foundation
import Gertie
import MacAppRoute

@testable import App
@testable import ClientInterfaces

public extension BlockedRequest {
  static var mock: Self {
    BlockedRequest(app: .init(bundleId: "com.foo"))
  }
}

extension CreateKeystrokeLines.KeystrokeLineInput: Mocked {
  public static var mock: Self {
    .init(
      appName: "Xcode",
      line: "import Foundation",
      filterSuspended: false,
      time: Date(timeIntervalSince1970: 0)
    )
  }

  public static var empty: Self {
    .init(
      appName: "",
      line: "",
      filterSuspended: false,
      time: Date(timeIntervalSince1970: 0)
    )
  }
}

extension Persistent.State: Mocked {
  public static var mock: Self {
    .init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .stable,
      filterVersion: "1.0.0",
      user: .mock
    )
  }

  public static var empty: Self {
    .init(
      appVersion: "",
      appUpdateReleaseChannel: .stable,
      filterVersion: "",
      user: .empty
    )
  }

  static var needsAppUpdate: Self {
    .init(
      appVersion: "0.9.9",
      appUpdateReleaseChannel: .stable,
      filterVersion: "0.9.9",
      user: .mock
    )
  }
}
