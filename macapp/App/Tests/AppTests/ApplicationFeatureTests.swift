import Core
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
    var checkIn = CheckIn_v2.Output.mock {
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

    // ⏰ we now receive a rule to block FaceSkype, but ONLY on a schedule
    store.deps.date = .constant(.day(.monday, at: "09:50")) // <-- in window
    let scheduledApp = BlockedApp(
      identifier: "FaceSkype",
      schedule: .init(mode: .active, days: .all, window: "09:00-17:00")
    )
    checkIn = CheckIn_v2.Output.mock {
      $0.userData.blockedApps = [scheduledApp]
    }
    await store.send(.checkIn(result: .success(checkIn), reason: .heartbeat)) {
      $0.user.data?.blockedApps = [scheduledApp]
    }

    await expect(terminateApp.calls.count).toEqual(1)
    await store.send(.application(.appLaunched(pid: 123)))
    await expect(terminateApp.calls.count).toEqual(2) // <-- blocked

    store.deps.date = .constant(.day(.monday, at: "17:01")) // <-- past window
    await store.send(.application(.appLaunched(pid: 123)))
    await expect(terminateApp.calls.count).toEqual(2) // <-- no longer blocked
  }

  @MainActor
  func testSendsFilterAliveOnWake() async {
    let (store, _) = AppReducer.testStore()
    let alive = mock(once: Result<Bool, XPCErr>.success(true))
    store.deps.filterXpc.sendAlive = alive.fn
    await store.send(.application(.didWake))
    await expect(alive.called).toEqual(true)
  }
}
