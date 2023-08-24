import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

@MainActor final class CheckInFeatureTests: XCTestCase {
  func testReceivingCheckInSuccess() async throws {
    let (store, _) = AppReducer.testStore {
      $0.user.data = .mock
      $0.user.numTimesUserTokenNotFound = 1
      $0.admin.accountStatus = .active
    }

    let setAccountActive = spy(on: Bool.self, returning: ())
    store.deps.api.setAccountActive = setAccountActive.fn

    let previousUserData = store.state.user.data

    let checkInResult = CheckIn.Output.mock {
      $0.userData.name = "little sammy 2"
      $0.userData.screenshotSize = 9876
      $0.updateReleaseChannel = .canary
      $0.latestRelease = .init(semver: "8.7.5")
      $0.adminAccountStatus = .needsAttention
    }

    await store.send(.checkIn(result: .success(checkInResult), reason: .heartbeat)) {
      $0.user.data = checkInResult.userData
      $0.user.data?.name = "little sammy 2"
      $0.user.data?.screenshotSize = 9876
      $0.user.numTimesUserTokenNotFound = 0
      $0.admin.accountStatus = .needsAttention
      $0.appUpdates.latestVersion = .init(semver: "8.7.5")
      $0.appUpdates.releaseChannel = .canary
    }

    await store.receive(.user(.updated(previous: previousUserData)))
    await expect(setAccountActive.invocations).toEqual([false])
  }

  func testReceivingCheckInDataStoresToPersistentState() async throws {
    let (store, _) = AppReducer.testStore()

    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    let checkInResult = CheckIn.Output.mock {
      $0.userData.name = "updated name"
      $0.updateReleaseChannel = .canary
    }

    await store.send(.checkIn(result: .success(checkInResult), reason: .heartbeat))

    await expect(saveState.invocations).toEqual([.init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .canary,
      filterVersion: "1.0.0",
      user: checkInResult.userData
    )])
  }

  func testCheckInInHeartbeat() async {
    let (store, bgQueue) = AppReducer.testStore()
    await store.send(.application(.didFinishLaunching)) // start heartbeat

    let output = CheckIn.Output.mock { $0.userData.screenshotSize = 999 }
    store.deps.api.checkIn = { _ in output }

    await bgQueue.advance(by: 60 * 19)
    expect(store.state.user.data?.screenshotSize).not.toEqual(999)

    await bgQueue.advance(by: 60)
    await store.receive(.checkIn(result: .success(output), reason: .heartbeat)) {
      $0.user.data?.screenshotSize = 999
    }
  }

  func testClickingCheckIn_Success_FilterReachable() async {
    let (store, bgQueue) = AppReducer.testStore()
    let notifications = spyOnNotifications(store)
    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .milliseconds(5))
    await store.receive(.filter(.receivedState(.installedAndRunning)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init("Refreshed rules successfully", "")])
  }

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

  func testClickingCheckIn_FilterError() async {
    let (store, bgQueue) = AppReducer.testStore()
    let notifications = spyOnNotifications(store)
    store.deps.filterXpc.sendUserRules = { _, _ in .failure(.unknownError("printer on fire")) }
    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .milliseconds(5))
    await store.receive(.filter(.receivedState(.installedAndRunning)))

    await store.send(.menuBar(.refreshRulesClicked))
    await expect(notifications).toEqual([.init(
      "Error refreshing rules",
      "We got updated rules, but there was an error sending them to the filter."
    )])
  }

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

  func testCheckingInAndInactiveAccounts() async {
    let (store, _) = AppReducer.testStore {
      $0.filter.extension = .installedAndRunning
      $0.admin.accountStatus = .inactive
      $0.user.data = .mock { $0.name = "old name" }
    }

    let setAccountActive = spy(on: Bool.self, returning: ())
    store.deps.api.setAccountActive = setAccountActive.fn
    store.deps.filterXpc.sendUserRules = { _, _ in fatalError() }

    let output1 = CheckIn.Output.mock {
      $0.adminAccountStatus = .inactive
      $0.userData.name = "new name"
    }
    let checkIn1 = spy(on: CheckIn.Input.self, returning: output1)
    store.deps.api.checkIn = checkIn1.fn

    await store.send(.heartbeat(.everyTwentyMinutes))
    await expect(checkIn1.invoked).toEqual(false)

    await store.send(.heartbeat(.everySixHours))
    await expect(checkIn1.invoked).toEqual(true)

    // we don't update anything if the account is inactive
    await store.receive(.checkIn(result: .success(output1), reason: .heartbeat)) {
      $0.user.data?.name = "old name"
    }
    await expect(setAccountActive.invocations).toEqual([false])

    // now, simulate the account owner fixing the issue
    let output2 = CheckIn.Output.mock {
      $0.adminAccountStatus = .active // <-- account is now active
      $0.userData.name = "new name"
    }
    let checkIn2 = spy(on: CheckIn.Input.self, returning: output2)
    store.deps.api.checkIn = checkIn2.fn
    store.deps.filterXpc.sendUserRules = { _, _ in .success(()) }

    await store.send(.heartbeat(.everySixHours))
    await expect(checkIn2.invoked).toEqual(true)

    await store.receive(.checkIn(result: .success(output2), reason: .heartbeat)) {
      $0.user.data?.name = "new name" // update data since account back to good
    }
    await expect(setAccountActive.invocations).toEqual([false, true])
  }
}
