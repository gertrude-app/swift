import ComposableArchitecture
import TestSupport
import XCTest
import XExpect

@testable import App
@testable import Models

@MainActor final class UpdateTests: XCTestCase {
  func testAppLaunchNoPersistentStateSavesNewState() async {
    let (store, _) = AppReducer.testStore()
    store.deps.storage.loadPersistentState = { nil }
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    await store.send(.application(.didFinishLaunching))
    await expect(saveState.invocations).toEqual([.init(appVersion: "1.0.0", user: nil)])
  }

  func testAppLaunchDetectingUpdateJustOccurred_HappyPath() async {
    let (store, _) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .needsAppUpdate }
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    let filterReplaced = mock(once: FilterInstallResult.installedSuccessfully)
    store.deps.filterExtension.replace = filterReplaced.fn

    // setup filter as installed, so it should replace
    store.deps.filterExtension.state = { .on }

    await store.send(.application(.didFinishLaunching))

    // we saved the new state
    await expect(saveState.invocations).toEqual([.init(appVersion: "1.0.0", user: .mock)])

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
    store.deps.filterExtension.state = { .on }
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
    store.deps.filterExtension.state = { .on }
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
}
