import Core
import Dependencies
import MacAppRoute

@testable import App
@testable import Models

public extension BlockedRequest {
  static var mock: Self {
    BlockedRequest(app: .init(bundleId: "com.foo"))
  }
}

extension Persistent.State {
  static func mock(config: (inout Self) -> Void) -> Self {
    var state = Self.mock
    config(&state)
    return state
  }

  static var mock: Self {
    .init(appVersion: "1.0.0", appUpdateReleaseChannel: .stable, user: .mock)
  }

  static var needsAppUpdate: Self {
    .init(appVersion: "0.9.9", appUpdateReleaseChannel: .stable, user: .mock)
  }
}
