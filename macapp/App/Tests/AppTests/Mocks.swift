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

extension CreateKeystrokeLines.KeystrokeLineInput: @retroactive Mocked {
  public static var mock: Self {
    .init(
      appName: "Xcode",
      line: "import Foundation",
      filterSuspended: false,
      time: Date(timeIntervalSince1970: 0),
    )
  }

  public static var empty: Self {
    .init(
      appName: "",
      line: "",
      filterSuspended: false,
      time: Date(timeIntervalSince1970: 0),
    )
  }
}

extension Persistent.State: @retroactive Mocked {
  public static var mock: Self {
    .init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .stable,
      filterVersion: "1.0.0",
      user: .mock,
      resumeOnboarding: nil,
    )
  }

  public static var empty: Self {
    .init(
      appVersion: "",
      appUpdateReleaseChannel: .stable,
      filterVersion: "",
      user: .empty,
      resumeOnboarding: nil,
    )
  }

  static func version(_ version: String) -> Self {
    .init(
      appVersion: version,
      appUpdateReleaseChannel: .stable,
      filterVersion: version,
      user: .mock,
      resumeOnboarding: nil,
    )
  }

  static var needsAppUpdate: Self {
    .init(
      appVersion: "0.9.9",
      appUpdateReleaseChannel: .stable,
      filterVersion: "0.9.9",
      user: .mock,
      resumeOnboarding: nil,
    )
  }
}

extension MacOSUser {
  static let dad = MacOSUser(id: 501, name: "Dad", type: .admin)
  static let franny = MacOSUser(id: 502, name: "Franny", type: .standard)
}

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}
