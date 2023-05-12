import Shared
import TestSupport
import XCTest
import XExpect

@testable import App
@testable import Models

@MainActor final class MonitoringReducerTests: XCTestCase {
  func testLoadingUserStateOnLaunchStartsScreenshotMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotSize = 1000
      $0.user?.screenshotFrequency = 60
    } }

    let (takeScreenshot, uploadScreenshot) = spyScreenshots(store)

    // prevent refresh rules from overriding persisted data
    store.deps.api.refreshRules = { _ in throw TestErr("API on fire") }

    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .seconds(60))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))
    await expect(takeScreenshot.invocations).toEqual([1000])
    await expect(uploadScreenshot.invocations).toEqual([.init(Data(), 999, 600)])

    await bgQueue.advance(by: .seconds(59))
    await expect(uploadScreenshot.invocations).toEqual([.init(Data(), 999, 600)])
    await expect(takeScreenshot.invocations).toEqual([1000])

    await bgQueue.advance(by: .seconds(1))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))
    await expect(takeScreenshot.invocations).toEqual([1000, 1000])
    await expect(uploadScreenshot.invocations).toEqual([
      .init(Data(), 999, 600),
      .init(Data(), 999, 600),
    ])
  }

  func testLoadingUserStateOnLaunchNoScreenshots() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.screenshotsEnabled = false
    } }

    // prevent refresh rules from overriding persisted data
    store.deps.api.refreshRules = { _ in throw TestErr("API on fire") }
    store.deps.monitoring.takeScreenshot = { _ in fatalError() }
    store.deps.api.uploadScreenshot = { _, _, _ in fatalError() }

    await store.send(.application(.didFinishLaunching))
    await bgQueue.advance(by: .seconds(60)) // <-- no fatal error
  }

  func testLoadingNilUserOnLaunchNoScreenshots() async {
    let (store, bgQueue) = AppReducer.testStore()

    // prevent refresh rules from overriding persisted data
    store.deps.api.refreshRules = { _ in throw TestErr("API on fire") }
    store.deps.monitoring.takeScreenshot = { _ in fatalError() }
    store.deps.api.uploadScreenshot = { _, _, _ in fatalError() }
    store.deps.storage.loadPersistentState = { .mock {
      $0.user = nil // <-- no user!
    } }

    await store.send(.application(.didFinishLaunching))
    await bgQueue.advance(by: .seconds(60)) // <-- no fatal error
  }

  func testGettingNewRulesStartsScreenshots() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.screenshotsEnabled = false
    } }

    // initial launch refresh, no screenshots
    store.deps.api.refreshRules = { _ in .mock { $0.screenshotsEnabled = false } }
    let (takeScreenshot, uploadScreenshot) = spyScreenshots(store)

    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .seconds(60))
    await expect(takeScreenshot.invoked).toEqual(false)
    await expect(uploadScreenshot.invoked).toEqual(false)

    // simulate new rules came in, from user click
    await store.send(.user(.refreshRules(result: .success(.mock {
      $0.screenshotsEnabled = true // <- enabled
      $0.screenshotsFrequency = 120 // <- every 2 minutes
      $0.screenshotsResolution = 1200
    }), userInitiated: true)))

    await bgQueue.advance(by: .seconds(60))
    await expect(takeScreenshot.invoked).toEqual(false)
    await expect(uploadScreenshot.invoked).toEqual(false)
    await bgQueue.advance(by: .seconds(60))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))
    await expect(takeScreenshot.invocations).toEqual([1200])
    await expect(uploadScreenshot.invocations).toEqual([.init(Data(), 999, 600)])
  }

  func testGettingNewRulesStopsScreenshots() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotSize = 700
      $0.user?.screenshotFrequency = 60
    } }

    store.deps.api.refreshRules = { _ in .mock {
      $0.screenshotsEnabled = true
      $0.screenshotsResolution = 700
      $0.screenshotsFrequency = 60
    } }

    let (takeScreenshot, uploadScreenshot) = spyScreenshots(store)

    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .seconds(60))
    await expect(takeScreenshot.invocations).toEqual([700])
    await expect(uploadScreenshot.invocations).toEqual([.init(Data(), 999, 600)])

    // simulate new rules came in, from user click
    await store.send(.user(.refreshRules(result: .success(.mock {
      $0.screenshotsEnabled = false // <- disabled
    }), userInitiated: true)))

    await bgQueue.advance(by: .seconds(600))
    await expect(takeScreenshot.invocations.count).toEqual(1) // no new invocations
    await expect(uploadScreenshot.invocations.count).toEqual(1)
  }

  func testConnectingUserStartsScreenshot() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { nil }
    store.deps.api.refreshRules = { _ in throw TestErr("API on fire") }

    let (takeScreenshot, uploadScreenshot) = spyScreenshots(store)

    await store.send(.application(.didFinishLaunching))
    await bgQueue.advance(by: .seconds(600))
    await expect(takeScreenshot.invocations.count).toEqual(0)
    await expect(uploadScreenshot.invocations.count).toEqual(0)

    // simulate user connect
    await store.send(.history(.userConnection(.connect(.success(.mock {
      $0.screenshotsEnabled = true
      $0.screenshotFrequency = 30
      $0.screenshotSize = 800
    })))))

    // now we start getting screenshots
    await bgQueue.advance(by: .seconds(30))
    await expect(takeScreenshot.invocations).toEqual([800])
    await expect(uploadScreenshot.invocations).toEqual([.init(Data(), 999, 600)])
  }

  func testDisconnectingUserStopsScreenshots() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.api.refreshRules = { _ in throw TestErr("API on fire") }
    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotFrequency = 60
    } }

    let (takeScreenshot, uploadScreenshot) = spyScreenshots(store)

    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .seconds(60))
    await expect(takeScreenshot.invocations.count).toEqual(1)
    await expect(uploadScreenshot.invocations.count).toEqual(1)

    // send disconnect
    await store.send(.adminAuthenticated(.adminWindow(.webview(.reconnectUserClicked))))

    await bgQueue.advance(by: .seconds(500))
    await expect(takeScreenshot.invocations.count).toEqual(1)
    await expect(uploadScreenshot.invocations.count).toEqual(1)
  }

  // helpers

  func spyScreenshots(_ store: TestStoreOf<AppReducer>)
    -> (
      takeScreenshot: Spy<(data: Data, width: Int, height: Int), Int>,
      uploadScreenshot: Spy3<URL, Data, Int, Int>
    ) {
    let takeScreenshot = spy(
      on: Int.self,
      returning: (data: Data(), width: 999, height: 600)
    )
    store.deps.monitoring.takeScreenshot = takeScreenshot.fn

    let uploadScreenshot = spy3(
      on: (Data.self, Int.self, Int.self),
      returning: URL(string: "/uploaded.png")!
    )
    store.deps.api.uploadScreenshot = uploadScreenshot.fn
    return (takeScreenshot, uploadScreenshot)
  }
}
