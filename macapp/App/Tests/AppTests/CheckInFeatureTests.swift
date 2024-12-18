import ConcurrencyExtras
import Core
import Gertie
import MacAppRoute
import TaggedTime
import TestSupport
import XCTest
import XExpect

@testable import App

final class CheckInFeatureTests: XCTestCase {
  @MainActor
  func testReceivingCheckInSuccess() async throws {
    let (store, _) = AppReducer.testStore {
      $0.user.data = .mock
      $0.user.numTimesUserTokenNotFound = 1
      $0.admin.accountStatus = .active
      $0.filter.extension = .installedAndRunning
      $0.user.downtimePausedUntil = .epoch + .minutes(20)
    }

    let setAccountActive = spy(on: Bool.self, returning: ())
    store.deps.api.setAccountActive = setAccountActive.fn

    let sentKeychains = LockIsolated<[[RuleKeychain]]>([])
    let sentDowntimes = LockIsolated<[Downtime?]>([])
    store.deps.filterXpc.sendUserRules = { _, keychains, downtime in
      sentKeychains.withValue { $0.append(keychains) }
      sentDowntimes.withValue { $0.append(downtime) }
      return .success(())
    }

    let previousUserData = store.state.user.data

    let keychain = RuleKeychain(keys: [.init(key: .skeleton(scope: .bundleId("com.foo")))])
    let checkInResult = CheckIn_v2.Output.mock {
      $0.keychains = [keychain]
      $0.userData.name = "little sammy 2"
      $0.userData.screenshotSize = 9876
      $0.userData.downtime = "22:00-05:00"
      $0.updateReleaseChannel = .canary
      $0.latestRelease = .init(semver: "8.7.5")
      $0.adminAccountStatus = .needsAttention
      $0.browsers = [.name("RadBrowser")]
    }

    await store.send(.checkIn(result: .success(checkInResult), reason: .heartbeat)) {
      $0.user.data = checkInResult.userData
      $0.user.data!.name = "little sammy 2"
      $0.user.data!.screenshotSize = 9876
      $0.user.data!.downtime = "22:00-05:00"
      $0.user.numTimesUserTokenNotFound = 0
      $0.admin.accountStatus = .needsAttention
      $0.appUpdates.latestVersion = .init(semver: "8.7.5")
      $0.appUpdates.releaseChannel = .canary
      $0.browsers = [.name("RadBrowser")]
    }

    await store.receive(.user(.updated(previous: previousUserData)))
    await expect(setAccountActive.calls).toEqual([false])
    expect(sentKeychains.value).toEqual([[keychain]])
    expect(sentDowntimes.value).toEqual([
      Downtime(
        window: "22:00-05:00",
        pausedUntil: .epoch + .minutes(20) // <-- we must pass along the pause
      ),
    ])
  }

  @MainActor
  func testReceivingCheckInDataStoresToPersistentState() async throws {
    let (store, _) = AppReducer.testStore()

    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    let checkInResult = CheckIn_v2.Output.mock {
      $0.userData.name = "updated name"
      $0.updateReleaseChannel = .canary
      $0.userData.downtime = "22:00-05:00"
    }

    await store.send(.checkIn(result: .success(checkInResult), reason: .heartbeat))

    await expect(saveState.calls).toEqual([.init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .canary,
      filterVersion: "1.0.0",
      user: CheckIn_v2.Output.mock {
        $0.userData.name = "updated name"
        $0.userData.downtime = "22:00-05:00"
      }.userData,
      resumeOnboarding: nil
    )])
  }

  @MainActor
  func testCheckInInHeartbeat() async {
    let (store, bgQueue) = AppReducer.testStore()
    // ignore checking num mac users
    store.deps.userDefaults.getInt = { _ in 3 }
    store.deps.userDefaults.setInt = { _, _ in }

    await store.send(.application(.didFinishLaunching)) // start heartbeat

    let output = CheckIn_v2.Output.mock { $0.userData.screenshotSize = 999 }
    store.deps.api.checkIn = { _ in output }

    await bgQueue.advance(by: 60 * 19)
    expect(store.state.user.data?.screenshotSize).not.toEqual(999)

    await bgQueue.advance(by: 60)
    await store.receive(.checkIn(result: .success(output), reason: .heartbeat)) {
      $0.user.data?.screenshotSize = 999
    }
  }

  @MainActor
  func testClickingCheckIn_Success_FilterReachable() async {
    let (store, bgQueue) = AppReducer.testStore()
    let notifications = spyOnNotifications(store)
    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .milliseconds(5))
    await store.receive(.filter(.receivedState(.installedAndRunning)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init("Refreshed rules successfully", "")])
  }

  @MainActor
  func testClickingCheckIn_Success_FilterUnreachable() async {
    let (store, bgQueue) = AppReducer.testStore()
    store.deps.filterExtension.setup = { .notInstalled }
    let notifications = spyOnNotifications(store)
    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .milliseconds(5))
    await store.receive(.filter(.receivedState(.notInstalled)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init("Refreshed rules successfully", "")])
  }

  @MainActor
  func testClickingCheckIn_FilterError() async {
    let (store, bgQueue) = AppReducer.testStore()
    let notifications = spyOnNotifications(store)
    store.deps.filterXpc.sendUserRules = { _, _, _ in .failure(.unknownError("printer on fire")) }
    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .milliseconds(5))
    await store.receive(.filter(.receivedState(.installedAndRunning)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init(
      "Error refreshing rules",
      "We got updated rules, but there was an error sending them to the filter."
    )])
  }

  @MainActor
  func testClickingCheckIn_ApiError() async {
    let (store, bgQueue) = AppReducer.testStore()
    store.deps.api.checkIn = { _ in throw TestErr("Oh noes!") }
    let notifications = spyOnNotifications(store)
    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .milliseconds(5))
    await store.receive(.filter(.receivedState(.installedAndRunning)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init(
      "Error refreshing rules",
      "Please try again, or contact support if the problem persists."
    )])
  }

  @MainActor
  func testCheckingInAndInactiveAccounts() async {
    let (store, _) = AppReducer.testStore {
      $0.filter.extension = .installedAndRunning
      $0.admin.accountStatus = .inactive
      $0.user.data = .mock { $0.name = "old name" }
    }

    let setAccountActive = spy(on: Bool.self, returning: ())
    store.deps.api.setAccountActive = setAccountActive.fn
    store.deps.filterXpc.sendUserRules = { _, _, _ in fatalError() }

    let output1 = CheckIn_v2.Output.mock {
      $0.adminAccountStatus = .inactive
      $0.userData.name = "new name"
    }
    let checkIn1 = spy(on: CheckIn_v2.Input.self, returning: output1)
    store.deps.api.checkIn = checkIn1.fn

    await store.send(.heartbeat(.everyTwentyMinutes))
    await expect(checkIn1.called).toEqual(false)

    await store.send(.heartbeat(.everySixHours))
    await expect(checkIn1.called).toEqual(true)

    // we don't update anything if the account is inactive
    await store.receive(.checkIn(result: .success(output1), reason: .heartbeat)) {
      $0.user.data?.name = "old name"
    }
    await expect(setAccountActive.calls).toEqual([false])

    // now, simulate the account owner fixing the issue
    let output2 = CheckIn_v2.Output.mock {
      $0.adminAccountStatus = .active // <-- account is now active
      $0.userData.name = "new name"
    }
    let checkIn2 = spy(on: CheckIn_v2.Input.self, returning: output2)
    store.deps.api.checkIn = checkIn2.fn
    store.deps.filterXpc.sendUserRules = { _, _, _ in .success(()) }

    await store.send(.heartbeat(.everySixHours))
    await expect(checkIn2.called).toEqual(true)

    await store.receive(.checkIn(result: .success(output2), reason: .heartbeat)) {
      $0.user.data?.name = "new name" // update data since account back to good
    }
    await expect(setAccountActive.calls).toEqual([false, true])
  }

  @MainActor
  func testGettingFilterSuspensionByClickingRefreshRules() async throws {
    let reqId = UUID()
    let (store, _) = AppReducer.testStore {
      $0.filter.extension = .installedAndRunning
      $0.requestSuspension.pending = .init(id: reqId, createdAt: .epoch)
    }
    let suspendFilter = spy(on: Seconds<Int>.self, returning: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.suspendFilter = suspendFilter.fn
    let notification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = notification.fn

    let checkInResult = CheckIn_v2.Output.empty {
      $0.resolvedFilterSuspension = .init(
        id: reqId,
        decision: .accepted(duration: 44, extraMonitoring: nil),
        comment: "ok!"
      )
    }

    await store.send(.checkIn(result: .success(checkInResult), reason: .userRefreshedRules)) {
      $0.requestSuspension.pending = nil
    }

    await expect(suspendFilter.calls).toEqual([44])

    // becuase they got a filter suspension, we don't want to show the normal
    // "Refreshed rules successfully" notification, only the filter suspension
    await expect(notification.calls.count).toEqual(1)
    await expect(notification.calls[0].a).toEqual("🟠 Temporarily disabling filter")
  }

  @MainActor
  func testGettingUnlockRequestDecisionsFromCheckIn() async throws {
    let (store, _) = AppReducer.testStore()
    let notification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = notification.fn

    let id1 = UUID()
    let id2 = UUID()
    let id3 = UUID()
    await store.send(.blockedRequests(.createUnlockRequests(.success(.init([id1, id2, id3]))))) {
      $0.blockedRequests.pendingUnlockRequests = [
        .init(id: id1, createdAt: .epoch),
        .init(id: id2, createdAt: .epoch),
        .init(id: id3, createdAt: .epoch),
      ]
    }

    let checkInResult = CheckIn_v2.Output.empty {
      $0.resolvedUnlockRequests = [
        .init(id: id1, status: .rejected, target: "foo.com", comment: nil),
        .init(id: id2, status: .accepted, target: "bar.com", comment: "ok"),
      ]
    }

    // because the unlocks came IN a checkIn, we don't need to check in again
    store.deps.api.checkIn = { _ in fatalError("not called") }

    await store.send(.checkIn(result: .success(checkInResult), reason: .pendingRequest)) {
      $0.blockedRequests.pendingUnlockRequests = [
        .init(id: id3, createdAt: .epoch),
      ]
    }

    await expect(notification.calls.count).toEqual(2) // one for each unlock request
  }

  @MainActor
  func testSendsNamedAppsInHeartbeat() async throws {
    let (store, _) = AppReducer.testStore()
    let listRunningApps = mockSync(returning: [[
      RunningApp(bundleId: "com.unnamed"), // <-- unnamed, won't be sent
      RunningApp(bundleId: "com.foo", bundleName: "Foo widget"),
    ]])
    store.deps.userDefaults = .mock
    store.deps.device.listRunningApps = listRunningApps.fn
    let checkIn = spy(on: CheckIn_v2.Input.self, returning: CheckIn_v2.Output.mock)
    store.deps.api.checkIn = checkIn.fn

    await store.send(.heartbeat(.everyTwentyMinutes))
    expect(listRunningApps.called).toEqual(true)
    await expect(checkIn.calls.count).toEqual(1)
    await expect(checkIn.calls[0].namedApps)
      .toEqual([.init(bundleId: "com.foo", bundleName: "Foo widget")])
  }
}
