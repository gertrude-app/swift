import ComposableArchitecture
import Core
import Gertie
import MacAppRoute
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
      filterVersion: "1.0.0",
      user: nil,
      resumeOnboarding: nil
    )])
  }

  func testAppLaunchDetectingUpdateJustOccurred_HappyPath() async {
    let (store, _) = AppReducer.testStore()

    store.deps.api.checkIn = { _ in throw TestErr("stop 2nd savePersistentState()") }
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
      filterVersion: "0.9.9",
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
    await expect(replaceFilterMock.invocations).toEqual(4)

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

  func testAppLaunchDetectingUpdateJustOccurred_OpensHealthCheckOnFilterCommunicationBroken() async {
    let (store, _) = AppReducer.testStore()
    store.deps.storage.loadPersistentState = { .needsAppUpdate }

    // filter replaces successfuly, and is known to be installed and running...
    store.deps.filterExtension.replace = mockFn(always: .installedSuccessfully)
    store.deps.filterExtension.state = { .installedAndRunning }

    // ... but the xpc connection is now broken
    store.deps.filterXpc.checkConnectionHealth = mockFn(always: .failure(.noConnection))
    store.deps.filterXpc.establishConnection = mockFn(always: .failure(.noConnection))

    await store.send(.application(.didFinishLaunching))
    await store.receive(.appUpdates(.delegate(.postUpdateFilterReplaceFailed)))

    // ...so open up the health check screen, so they can repair/restart
    expect(store.state.adminWindow.windowOpen).toEqual(true)
    expect(store.state.adminWindow.screen).toEqual(.healthCheck)
  }
}
