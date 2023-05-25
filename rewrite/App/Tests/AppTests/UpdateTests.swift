import ComposableArchitecture
import Core
import Shared
import TestSupport
import XCTest
import XExpect

@testable import App
@testable import ClientInterfaces

@MainActor final class UpdateTests: XCTestCase {
  func testAppLaunchNoPersistentStateSavesNewState() async {
    let (store, _) = AppReducer.testStore()
    store.deps.storage.loadPersistentState = { nil }
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    await store.send(.application(.didFinishLaunching))
    await expect(saveState.invocations).toEqual([.init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .stable,
      user: nil
    )])
  }

  func testAppLaunchDetectingUpdateJustOccurred_HappyPath() async {
    let (store, _) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .needsAppUpdate }
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    let filterReplaced = mock(once: FilterInstallResult.installedSuccessfully)
    store.deps.filterExtension.replace = filterReplaced.fn

    // setup filter as installed, so it should replace
    store.deps.filterExtension.state = { .installedAndRunning }

    await store.send(.application(.didFinishLaunching))

    // we saved the new state
    await expect(saveState.invocations).toEqual([.init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .stable,
      user: .mock
    )])

    // and replaced the filter
    await expect(filterReplaced.invoked).toEqual(true)
  }

  func testAppLaunchDetectingUpdateJustOccurred_RepeatsFilterReplaceOnFail() async {
    let (store, _) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .needsAppUpdate }
    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()

    let replaceFilterMock = mock(
      returning: [FilterInstallResult.timedOutWaiting],
      then: .installedSuccessfully
    )
    store.deps.filterExtension.replace = replaceFilterMock.fn
    store.deps.filterExtension.state = { .installedAndRunning }
    store.deps.filterXpc.checkConnectionHealth = mockFn(
      returning: [.failure(.timeout)],
      then: .success(())
    )

    await store.send(.application(.didFinishLaunching))

    await expect(replaceFilterMock.invocations).toEqual(1)
    await scheduler.advance(by: .milliseconds(501))
    await expect(replaceFilterMock.invocations).toEqual(2)
    expect(store.state.adminWindow.windowOpen).toEqual(false)
  }

  func testAppLaunchDetectingUpdateJustOccurred_OpensHealthCheckOnRepeatFail() async {
    let (store, _) = AppReducer.testStore()
    store.deps.storage.loadPersistentState = { .needsAppUpdate }

    let replaceFilterMock = mock(always: FilterInstallResult.timedOutWaiting)
    store.deps.filterExtension.replace = replaceFilterMock.fn
    store.deps.filterExtension.state = { .installedAndRunning }
    store.deps.filterXpc.checkConnectionHealth = mockFn(always: .failure(.timeout))

    await store.send(.application(.didFinishLaunching))
    await expect(replaceFilterMock.invocations).toEqual(2)

    await store.receive(.appUpdates(.delegate(.postUpdateFilterReplaceFailed)))

    expect(store.state.adminWindow.windowOpen).toEqual(true)
    expect(store.state.adminWindow.screen).toEqual(.healthCheck)
  }

  func testAppLaunchDetectingUpdateJustOccurred_OpensHealthCheckOnNotInstalled() async {
    let (store, _) = AppReducer.testStore()
    store.deps.storage.loadPersistentState = { .needsAppUpdate }

    store.deps.filterExtension.state = { .notInstalled } // <-- weird for post update...

    await store.send(.application(.didFinishLaunching))
    await store.receive(.appUpdates(.delegate(.postUpdateFilterNotInstalled)))

    // ...so open up the health check screen, just in case
    expect(store.state.adminWindow.windowOpen).toEqual(true)
    expect(store.state.adminWindow.screen).toEqual(.healthCheck)
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

  func testTriggeredUpdateSavesToCorrectChannel() async {
    let (store, _) = AppReducer.testStore { $0.appUpdates.releaseChannel = .beta }
    let triggerUpdate = spy(on: String.self, returning: ())
    store.deps.updater.triggerUpdate = triggerUpdate.fn

    await store.send(.adminWindow(.delegate(.triggerAppUpdate)))
    await expect(triggerUpdate.invocations)
      .toEqual(["http://127.0.0.1:8080/appcast.xml?channel=beta"])
  }

  func testHeartbeatCheck_TriggersUpdateSavingStateWhenBehind() async {
    let (store, scheduler) = AppReducer.testStore()
    let latestAppVersion = spy(on: ReleaseChannel.self, returning: "3.9.99")
    store.deps.api.latestAppVersion = latestAppVersion.fn
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    let triggerUpdate = spy(on: String.self, returning: ())
    store.deps.updater.triggerUpdate = triggerUpdate.fn

    await store.send(.application(.didFinishLaunching))
    await scheduler.advance(by: .seconds(60 * 60 * 6 - 1)) // one second before 6 hours
    await expect(latestAppVersion.invoked).toEqual(false)
    await expect(saveState.invoked).toEqual(false)
    await expect(triggerUpdate.invoked).toEqual(false)

    await scheduler.advance(by: .seconds(1))
    await Task.repeatYield(count: 20)

    await expect(latestAppVersion.invoked).toEqual(true)
    await expect(saveState.invoked).toEqual(true)
    await expect(triggerUpdate.invocations)
      .toEqual(["http://127.0.0.1:8080/appcast.xml?channel=stable"])
  }

  func testHeartbeatCheck_DoesntTriggerUpdateWhenUpToDate() async {
    let (store, scheduler) = AppReducer.testStore()
    store.deps.api.latestAppVersion = { _ in "1.0.0" } // <-- same as current
    let triggerUpdate = spy(on: String.self, returning: ())
    store.deps.updater.triggerUpdate = triggerUpdate.fn

    await store.send(.application(.didFinishLaunching))
    await scheduler.advance(by: .seconds(60 * 60 * 6))

    await expect(triggerUpdate.invoked).toEqual(false)
  }

  func testUpdatingReleaseChannelSetsStateAndSavesPersistent() async {
    let (store, _) = AppReducer.testStore()
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    await store.send(.adminWindow(.webview(.releaseChannelUpdated(channel: .beta)))) {
      $0.appUpdates.releaseChannel = .beta
    }
    await expect(saveState.invoked).toEqual(true)
  }
}
