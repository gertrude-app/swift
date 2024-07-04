import ComposableArchitecture
import Core
import Gertie
import MacAppRoute
import TaggedTime
import TestSupport
import XCTest
import XExpect

@testable import App
@testable import ClientInterfaces

@MainActor final class AdminWindowFeatureTests: XCTestCase {
  /// NB: see https://github.com/gertrude-app/project/issues/163
  /// for context, and future directions when `filtering` becomes option
  func testAllNonCurrentUsersConsideredExemptable() async {
    await withDependencies {
      $0.app.installedVersion = { "1.0.0" }
    } operation: {
      let (store, _) = AppReducer.testStore(mockDeps: false) {
        $0.adminWindow.windowOpen = true
        $0.user = .init(data: .mock)
        $0.history.userConnection = .established(welcomeDismissed: true)
      }

      // this replicates rachel's current setup, she is protected + exempt
      await store.send(.adminWindow(.setExemptionData(
        .ok(value: [
          .init(id: 503, name: "Monitored", type: .standard),
          .init(id: 501, name: "Rachel", type: .admin),
        ]),
        .ok(value: .init(exempt: [501], protected: [503, 502, 501]))
      )))

      let viewState = AdminWindowFeature.State.View(rootState: store.state)
      expect(viewState.exemptableUsers).toEqual(.ok(value: [
        .init(id: 503, name: "Monitored", isAdmin: false, isExempt: false),
        .init(id: 501, name: "Rachel", isAdmin: true, isExempt: true),
      ]))
    }
  }

  func testDisconnectUserClicked() async {
    let (store, _) = AppReducer.testStore(mockDeps: false) {
      $0.adminWindow.windowOpen = true
      $0.user = .init(data: .mock)
      $0.history.userConnection = .established(welcomeDismissed: true)
    }

    store.deps.websocket = .mock
    store.deps.app = .mock
    let clearUserToken = mock(once: ())
    store.deps.api.clearUserToken = clearUserToken.fn
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    store.deps.storage.loadPersistentState = { .mock }
    let filterNotify = mock(once: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.disconnectUser = filterNotify.fn
    let securityEvent = spy2(on: (LogSecurityEvent.Input.self, UUID?.self), returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn

    await store.send(.adminAuthed(.adminWindow(.webview(.disconnectUserClicked)))) {
      $0.history.userConnection = .notConnected
      $0.user = .init()
      $0.adminWindow.windowOpen = false
      $0.menuBar.dropdownOpen = true
    }

    await expect(clearUserToken.invoked).toEqual(true)
    await expect(filterNotify.invoked).toEqual(true)
    await expect(saveState.invocations).toEqual([.init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .stable,
      filterVersion: "1.0.0",
      user: nil,
      resumeOnboarding: nil
    )])
    await expect(securityEvent.invocations)
      .toEqual([Both(.init(.childDisconnected, "name: Mock User"), nil)])
  }

  func testSuspendFilter() async {
    let (store, _) = AppReducer.testStore()

    let suspendFilter = spy(
      on: Seconds<Int>.self,
      returning: Result<Void, XPCErr>.success(())
    )
    store.deps.filterXpc.suspendFilter = suspendFilter.fn

    await store.send(
      .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(durationInSeconds: 90))))
    ) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 90)
    }

    await expect(suspendFilter.invocations).toEqual([.init(90)])
  }

  func testLatestAppResponseFromHealthCheckDoesntTriggerUpdate() async {
    let (store, _) = AppReducer.testStore {
      $0.appUpdates.installedVersion = "1.0.0"
    }

    let triggerUpdate = spy(on: String.self, returning: ())
    store.deps.updater.triggerUpdate = triggerUpdate.fn

    let checkInRes = CheckIn.Output.mock { $0.latestRelease = .init(semver: "2.0.0") }

    await store.send(.checkIn(result: .success(checkInRes), reason: .healthCheck))
    await expect(triggerUpdate.invoked).toEqual(false)

    // but the heartbeat will pick up the new version and prompt
    await store.send(.heartbeat(.everySixHours))
    await expect(triggerUpdate.invoked).toEqual(true)
  }
}
