import Gertie
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

final class ApplicationFeatureTests: XCTestCase {
  @MainActor
  func testAppBlocking() async {
    let (store, _) = AppReducer.testStore {
      $0.user.data = .mock { $0.blockedApps = [] } // <-- no blocked apps
    }

    store.deps.device.runningAppFromPid = { pid in
      pid == 123 ? .init(pid: 123, bundleId: "com.faceskype", bundleName: "FaceSkype") : nil
    }
    let notification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = notification.fn
    let securityEvent = spy2(on: (LogSecurityEvent.Input.self, UUID?.self), returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn
    let terminateAll = spy(on: [BlockedApp].self, returning: ())
    store.deps.device.terminateBlockedApps = terminateAll.fn
    let terminateApp = spy(on: RunningApp.self, returning: ())
    store.deps.device.terminateApp = terminateApp.fn

    // launching FaceSkype does nothing
    await store.send(.application(.appLaunched(pid: 123)))
    await expect(notification.called).toEqual(false)
    await expect(securityEvent.called).toEqual(false)
    await expect(terminateAll.called).toEqual(false)
    await expect(terminateApp.called).toEqual(false)

    // we now receive a rule to block FaceSkype
    let checkIn = CheckIn_v2.Output.mock {
      $0.userData.blockedApps = [.init(identifier: "FaceSkype")]
    }
    await store.send(.checkIn(result: .success(checkIn), reason: .heartbeat)) {
      $0.user.data?.blockedApps = [.init(identifier: "FaceSkype")]
    }

    // heartbeat now attempts terminates it
    await store.send(.heartbeat(.everyMinute))
    await expect(terminateAll.calls).toEqual([[.init(identifier: "FaceSkype")]])

    // attempt to launch blocked app
    await store.send(.application(.appLaunched(pid: 123)))
    await expect(terminateApp.calls)
      .toEqual([.init(pid: 123, bundleId: "com.faceskype", bundleName: "FaceSkype")])
    await expect(notification.calls)
      .toEqual([.init("Application blocked", "The app “FaceSkype” is not allowed")])
    await expect(securityEvent.calls)
      .toEqual([Both(.init(.blockedAppLaunchAttempted, "app: FaceSkype"), nil)])
  }
}
