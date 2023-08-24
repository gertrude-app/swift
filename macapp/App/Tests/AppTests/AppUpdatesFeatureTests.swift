import Dependencies
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

@MainActor final class AppUpdatesFeatureTests: XCTestCase {
  func testReceivingLatestVersionFromCheckInSetsLatestReleaseAndChannel() async {
    let (store, _) = AppReducer.testStore {
      $0.appUpdates.releaseChannel = .stable
      $0.appUpdates.installedVersion = "1.0.0"
      $0.appUpdates.latestVersion = nil
    }
    store.deps.date = .constant(.epoch)

    let latestRelease = CheckIn.LatestRelease(
      semver: "1.1.0",
      pace: .init(
        nagOn: .epoch.advanced(by: .days(10)),
        requireOn: .epoch.advanced(by: .days(20))
      )
    )

    let checkInRes = CheckIn.Output.mock {
      $0.latestRelease = latestRelease
      $0.updateReleaseChannel = .beta
    }

    await store.send(.checkIn(result: .success(checkInRes), reason: .heartbeat)) {
      $0.appUpdates.latestVersion = latestRelease
      $0.appUpdates.releaseChannel = .beta
    }

    await store.send(.menuBar(.updateNagDismissClicked)) {
      $0.appUpdates.updateNagDismissedUntil = .epoch.advanced(by: .hours(26))
    }
  }

  func testHeartbeatCleansUpNagDismissal() async {
    let (store, _) = AppReducer.testStore {
      $0.appUpdates.releaseChannel = .stable
      $0.appUpdates.installedVersion = "1.0.0"
      $0.appUpdates.latestVersion = .init(semver: "1.1.0")
      $0.appUpdates.updateNagDismissedUntil = .epoch.advanced(by: .days(3))
    }
    store.deps.date = .constant(.epoch.advanced(by: .days(4)))
    await store.send(.heartbeat(.everyHour)) {
      $0.appUpdates.updateNagDismissedUntil = nil
    }
  }

  func testMenuBarUpdateState() async {
    let cases: [(AppUpdatesFeature.State, MenuBarFeature.State.View.Connected.UpdateStatus?)] = [
      (.init(installedVersion: "1.0.0", latestVersion: nil), nil),
      (.init(installedVersion: "1.0.0", latestVersion: .init(semver: "1.1.0")), .available),
      (
        .init(
          installedVersion: "1.0.0",
          latestVersion: .init(
            semver: "1.1.0",
            pace: .init(
              nagOn: .epoch.advanced(by: .days(25)), // <-- not in nag period yet
              requireOn: .epoch.advanced(by: .days(35))
            )
          )
        ),
        .available
      ),
      (
        .init(
          installedVersion: "1.0.0",
          latestVersion: .init(
            semver: "1.1.0",
            pace: .init(
              nagOn: .epoch.advanced(by: .days(15)), // <-- within nag period
              requireOn: .epoch.advanced(by: .days(30))
            )
          )
        ),
        .nag
      ),
      (
        .init(
          installedVersion: "1.0.0",
          latestVersion: .init(
            semver: "1.1.0",
            pace: .init(
              nagOn: .epoch.advanced(by: .days(15)), // <-- within nag period...
              requireOn: .epoch.advanced(by: .days(30))
            )
          ),
          updateNagDismissedUntil: .epoch.advanced(by: .days(21)) // <-- ...but dismissed
        ),
        .available
      ),
      (
        .init(
          installedVersion: "1.0.0",
          latestVersion: .init(
            semver: "1.1.0",
            pace: .init(
              nagOn: .epoch.advanced(by: .days(5)),
              requireOn: .epoch.advanced(by: .days(10)) // <-- within require period
            )
          ),
          updateNagDismissedUntil: .epoch.advanced(by: .days(21)) // <-- no effect
        ),
        .require
      ),
    ]

    for (state, expected) in cases {
      let menuState = withDependencies {
        $0.date = .constant(.epoch.advanced(by: .days(20)))
      } operation: {
        let (store, _) = AppReducer.testStore {
          $0.appUpdates = state
          $0.history.userConnection = .established(welcomeDismissed: true)
          $0.user = .init(data: .mock)
        }
        return store.state.menuBarView
      }
      if case .connected(let connected) = menuState {
        expect(connected.updateStatus).toEqual(expected)
      } else {
        XCTFail("Expected menu bar state to be connected")
      }
    }
  }

  func testTriggeredUpdateSavesStateAndCallsMethodOnClient() async {
    let (store, _) = AppReducer.testStore()
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    let triggerUpdate = spy(on: String.self, returning: ())
    store.deps.updater.triggerUpdate = triggerUpdate.fn

    await store.send(.adminWindow(.delegate(.triggerAppUpdate)))
    await expect(saveState.invoked).toEqual(true)
    await expect(triggerUpdate.invocations)
      .toEqual(["http://127.0.0.1:8080/appcast.xml?channel=stable"])
  }

  func testTriggeredUpdateChecksCorrectChannel() async {
    let (store, _) = AppReducer.testStore { $0.appUpdates.releaseChannel = .beta }
    let triggerUpdate = spy(on: String.self, returning: ())
    store.deps.updater.triggerUpdate = triggerUpdate.fn

    await store.send(.adminWindow(.delegate(.triggerAppUpdate)))
    await expect(triggerUpdate.invocations)
      .toEqual(["http://127.0.0.1:8080/appcast.xml?channel=beta"])
  }

  func testHeartbeatCheck_TriggersUpdateSavingStateWhenBehind() async {
    let (store, scheduler) = AppReducer.testStore {
      $0.appUpdates.latestVersion = .init(semver: "3.9.0") // <-- update available
    }

    // every successful app check-in saves state, which complicates asserting that
    // trigging an update also saves state, so disable all check-ins by throwing
    store.deps.api.checkIn = { _ in throw TestErr("stop check-in") }

    store.deps.storage.loadPersistentState = { .mock { $0.appUpdateReleaseChannel = .beta } }
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    let triggerUpdate = spy(on: String.self, returning: ())
    store.deps.updater.triggerUpdate = triggerUpdate.fn

    await store.send(.application(.didFinishLaunching)) // <-- start the heartbeat
    await scheduler.advance(by: .seconds(60 * 60 * 6 - 1)) // one second before 6 hours
    await expect(saveState.invoked).toEqual(false)
    await expect(triggerUpdate.invoked).toEqual(false)

    await scheduler.advance(by: .seconds(1))
    await Task.repeatYield(count: IS_CI ? 60 : 25)

    await expect(saveState.invoked).toEqual(true)
    await expect(triggerUpdate.invocations)
      .toEqual(["http://127.0.0.1:8080/appcast.xml?channel=beta"])
  }

  func testHeartbeatCheck_DoesntTriggerUpdateWhenUpToDate() async {
    let (store, scheduler) = AppReducer.testStore()

    store.deps.api.checkIn = { _ in .mock {
      $0.latestRelease = .init(semver: "1.0.0") // <-- same as current
    } }

    let triggerUpdate = spy(on: String.self, returning: ())
    store.deps.updater.triggerUpdate = triggerUpdate.fn

    await store.send(.application(.didFinishLaunching)) // <-- start the heartbeat
    await scheduler.advance(by: .seconds(60 * 60 * 6))

    await expect(triggerUpdate.invoked).toEqual(false)
  }
}
