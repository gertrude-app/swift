import ComposableArchitecture
import Core
import Gertie
import TaggedTime
import TestSupport
import XCTest
import XExpect

@testable import App
@testable import ClientInterfaces

@MainActor final class AdminWindowTests: XCTestCase {
  func testReconnectUserClicked() async {
    let (store, _) = AppReducer.testStore {
      $0.adminWindow.windowOpen = true
      $0.user = .init(data: .mock)
      $0.history.userConnection = .established(welcomeDismissed: true)
    }

    let clearUserToken = mock(once: ())
    store.deps.api.clearUserToken = clearUserToken.fn
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    let filterNotify = mock(once: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.disconnectUser = filterNotify.fn

    await store.send(.adminAuthenticated(.adminWindow(.webview(.reconnectUserClicked)))) {
      $0.history.userConnection = .notConnected
      $0.user = nil
      $0.adminWindow.windowOpen = false
      $0.menuBar.dropdownOpen = true
    }

    await expect(clearUserToken.invoked).toEqual(true)
    await expect(filterNotify.invoked).toEqual(true)
    await expect(saveState.invocations).toEqual([.init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .stable,
      user: nil
    )])
  }

  func testSuspendFilter() async {
    let (store, _) = AppReducer.testStore()

    let suspendFilter = spy(
      on: Seconds<Int>.self,
      returning: Result<Void, XPCErr>.success(())
    )
    store.deps.filterXpc.suspendFilter = suspendFilter.fn

    await store.send(
      .adminAuthenticated(.adminWindow(.webview(.suspendFilterClicked(durationInSeconds: 90))))
    ) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 90)
    }

    await expect(suspendFilter.invocations).toEqual([.init(90)])
  }

  func testResumeSuspension() async {
    let (store, _) = AppReducer.testStore {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 90)
    }

    let filterNotify = mock(once: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.endFilterSuspension = filterNotify.fn
    let notification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = notification.fn
    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()
    let quitBrowsers = mock(once: ())
    store.deps.device.quitBrowsers = quitBrowsers.fn

    await store.send(.adminWindow(.webview(.resumeFilterClicked))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await expect(filterNotify.invoked).toEqual(true)
    await expect(notification.invocations).toEqual([.init(
      "⚠️ Web browsers quitting soon!",
      "Filter suspension ended. All browsers will quit in 60 seconds. Save any important work NOW."
    )])

    await scheduler.advance(by: 59)
    await expect(quitBrowsers.invoked).toEqual(false)
    await scheduler.advance(by: 1)
    await expect(quitBrowsers.invoked).toEqual(true)
  }

  func testLatestAppResponseFromHealthCheckDoesntTriggerUpdate() async {
    let (store, _) = AppReducer.testStore {
      $0.appUpdates.installedVersion = "1.0.0"
    }

    let triggerUpdate = spy(on: String.self, returning: ())
    store.deps.updater.triggerUpdate = triggerUpdate.fn

    await store.send(.appUpdates(.latestVersionResponse(
      result: .success(.init(semver: "2.0.0", pace: nil)),
      source: .healthCheck // <-- healthCheck, therefore no update
    )))

    await expect(triggerUpdate.invoked).toEqual(false)

    // but a HEARTBEAT-triggered update DOES
    await store.send(.appUpdates(.latestVersionResponse(
      result: .success(.init(semver: "2.0.0", pace: nil)),
      source: .heartbeat
    )))

    await expect(triggerUpdate.invoked).toEqual(true)
  }
}
