import Gertie
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App
@testable import ClientInterfaces

@MainActor final class MonitoringReducerTests: XCTestCase {

  func testLoadingUserStateOnLaunchStartsMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.keyloggingEnabled = true
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotSize = 1000
      $0.user?.screenshotFrequency = 60
    } }

    let (takeScreenshot, uploadScreenshot, takePendingScreenshots) = spyScreenshots(store)
    let keylogging = spyKeylogging(store)

    store.deps.api.refreshRules = { _ in throw TestErr("stop launch refresh") }

    await store.send(.application(.didFinishLaunching))

    await expect(keylogging.start.invoked).toEqual(true)

    await bgQueue.advance(by: .seconds(60))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))
    await expect(takeScreenshot.invocations).toEqual([1000])
    await expect(uploadScreenshot.invocations).toEqual([.init(Data(), 999, 600, .epoch)])
    await expect(takePendingScreenshots.invocations).toEqual(1)

    await bgQueue.advance(by: .seconds(59))
    await expect(uploadScreenshot.invocations).toEqual([.init(Data(), 999, 600, .epoch)])
    await expect(takeScreenshot.invocations).toEqual([1000])

    await bgQueue.advance(by: .seconds(1))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))
    await expect(takeScreenshot.invocations).toEqual([1000, 1000])
    await expect(takePendingScreenshots.invocations).toEqual(2)
    await expect(uploadScreenshot.invocations).toEqual([
      .init(Data(), 999, 600, .epoch),
      .init(Data(), 999, 600, .epoch),
    ])

    await expect(keylogging.take.invoked).toEqual(false)
    await expect(keylogging.upload.invoked).toEqual(false)
    await bgQueue.advance(by: .seconds(60 * 3))
    await expect(keylogging.take.invoked).toEqual(true)
    await expect(keylogging.upload.invoked).toEqual(true)
  }

  func testNotGrantedPermissionsThenFixed() async {
    let (store, bgQueue) = AppReducer.testStore()

    // user is monitored...
    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.keyloggingEnabled = true
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotSize = 1000
      $0.user?.screenshotFrequency = 60
    } }

    // ...but permissions are not granted
    store.deps.monitoring.screenRecordingPermissionGranted = { false }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { false }

    store.deps.api.refreshRules = { _ in throw TestErr("stop launch refresh") }
    let (takeScreenshot, uploadScreenshot, _) = spyScreenshots(store)
    let keylogging = spyKeylogging(store, keystrokes: mock(
      returning: [nil],
      then: [.mock]
    ))

    await store.send(.application(.didFinishLaunching))

    // without permissions, no monitoring happens
    await expect(keylogging.stop.invoked).toEqual(true)
    await expect(keylogging.start.invoked).toEqual(false)
    await bgQueue.advance(by: .seconds(60 * 5)) // <- to heartbeat
    await expect(keylogging.upload.invoked).toEqual(false)
    await expect(takeScreenshot.invoked).toEqual(false)
    await expect(uploadScreenshot.invoked).toEqual(false)

    // but, simulate permissions fixed...
    store.deps.monitoring.screenRecordingPermissionGranted = { true }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { true }

    // ...and send a health-check recheck event...
    await store.send(.adminWindow(.webview(.healthCheck(action: .recheckClicked))))

    // ...and now monitoring should start up
    await expect(keylogging.start.invoked).toEqual(true)
    await bgQueue.advance(by: .seconds(60 * 5)) // <- to heartbeat
    await expect(keylogging.upload.invoked).toEqual(true)
    await expect(takeScreenshot.invoked).toEqual(true)
    await expect(uploadScreenshot.invoked).toEqual(true)
  }

  func testLoadingUserStateOnLaunchNoMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.screenshotsEnabled = false
      $0.user?.keyloggingEnabled = false
    } }

    store.deps.api.refreshRules = { _ in throw TestErr("stop launch refresh") }
    store.deps.monitoring.takeScreenshot = { _ in fatalError() }
    store.deps.api.uploadScreenshot = { _, _, _, _ in fatalError() }
    let keylogging = spyKeylogging(store, keystrokes: mock(always: nil))

    await store.send(.application(.didFinishLaunching))
    await bgQueue.advance(by: .seconds(600))
    await expect(keylogging.take.invoked).toEqual(true) // we always check
    await expect(keylogging.upload.invoked).toEqual(false)
  }

  func testLoadingNilUserOnLaunchNoMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.api.refreshRules = { _ in throw TestErr("stop launch refresh") }
    store.deps.monitoring.takeScreenshot = { _ in fatalError() }
    store.deps.api.uploadScreenshot = { _, _, _, _ in fatalError() }
    let keylogging = spyKeylogging(store, keystrokes: mock(always: nil))
    store.deps.storage.loadPersistentState = { .mock {
      $0.user = nil // <-- no user!
    } }

    await store.send(.application(.didFinishLaunching))
    await bgQueue.advance(by: .seconds(600)) // <-- no fatal error
    await expect(keylogging.take.invoked).toEqual(true) // we always check
    await expect(keylogging.upload.invoked).toEqual(false)
  }

  func testGettingNewRulesStartsMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.screenshotsEnabled = false
      $0.user?.keyloggingEnabled = false
    } }

    // initial launch refresh, no screenshots
    store.deps.api.refreshRules = { _ in .mock {
      $0.screenshotsEnabled = false
      $0.keyloggingEnabled = false
    } }
    let (takeScreenshot, uploadScreenshot, _) = spyScreenshots(store)
    let keylogging = spyKeylogging(store, keystrokes: mock(
      returning: [nil],
      then: [.mock]
    ))

    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .seconds(300))
    await expect(takeScreenshot.invoked).toEqual(false)
    await expect(uploadScreenshot.invoked).toEqual(false)
    await expect(keylogging.upload.invoked).toEqual(false)

    // simulate new rules came in, from user click
    await store.send(.user(.refreshRules(result: .success(.mock {
      $0.keyloggingEnabled = true // <- enabled
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
    await expect(uploadScreenshot.invocations).toEqual([.init(Data(), 999, 600, .epoch)])
    await bgQueue.advance(by: .seconds(60 * 3)) // advance to heartbeat
    await Task.repeatYield()
    await expect(keylogging.upload.invoked).toEqual(true)
  }

  func testGettingNewRulesStopsMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.keyloggingEnabled = true
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotSize = 700
      $0.user?.screenshotFrequency = 60
    } }

    store.deps.api.refreshRules = { _ in .mock {
      $0.keyloggingEnabled = true
      $0.screenshotsEnabled = true
      $0.screenshotsResolution = 700
      $0.screenshotsFrequency = 60
    } }

    let (takeScreenshot, uploadScreenshot, _) = spyScreenshots(store)
    let keylogging = spyKeylogging(store, keystrokes: mock(
      returning: [[.mock]],
      then: .some(nil)
    ))

    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .seconds(60))
    await Task.repeatYield()
    await expect(takeScreenshot.invocations).toEqual([700])
    await expect(uploadScreenshot.invocations).toEqual([.init(Data(), 999, 600, .epoch)])
    await bgQueue.advance(by: .seconds(60 * 4)) // <- to heartbeat
    await expect(keylogging.upload.invocations.count).toEqual(1)
    await expect(takeScreenshot.invocations.count).toEqual(5)
    await expect(uploadScreenshot.invocations.count).toEqual(5)

    // simulate new rules came in, from user click
    await store.send(.user(.refreshRules(result: .success(.mock {
      $0.keyloggingEnabled = false // <-- disabled
      $0.screenshotsEnabled = false // <-- disabled
    }), userInitiated: true)))

    await bgQueue.advance(by: .seconds(60 * 5))

    // no new invocations for any of these...
    await expect(keylogging.upload.invocations.count).toEqual(1)
    await expect(takeScreenshot.invocations.count).toEqual(5)
    await expect(uploadScreenshot.invocations.count).toEqual(5)
  }

  func testConnectingUserStartsMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { nil }
    store.deps.api.refreshRules = { _ in throw TestErr("stop launch refresh") }

    let (takeScreenshot, uploadScreenshot, _) = spyScreenshots(store)
    let keylogging = spyKeylogging(store, keystrokes: mock(
      returning: [nil],
      then: [.mock]
    ))

    await store.send(.application(.didFinishLaunching))
    await bgQueue.advance(by: .seconds(60 * 5)) // <- to heartbeat
    await expect(takeScreenshot.invocations.count).toEqual(0)
    await expect(uploadScreenshot.invocations.count).toEqual(0)
    await expect(keylogging.upload.invocations.count).toEqual(0)

    // simulate user connect
    await store.send(.history(.userConnection(.connect(.success(.mock {
      $0.keyloggingEnabled = true
      $0.screenshotsEnabled = true
      $0.screenshotFrequency = 45
      $0.screenshotSize = 800
    })))))

    // now we start getting screenshots, and keystrokes
    await bgQueue.advance(by: .seconds(60))
    await expect(takeScreenshot.invocations).toEqual([800])
    await expect(uploadScreenshot.invocations).toEqual([.init(Data(), 999, 600, .epoch)])
    await bgQueue.advance(by: .seconds(60 * 4)) // <- to heartbeat
    await Task.repeatYield()
    await expect(keylogging.upload.invocations.count).toEqual(1)
  }

  func testDisconnectingUserStopsMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.api.refreshRules = { _ in throw TestErr("stop launch refresh") }
    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.keyloggingEnabled = true
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotFrequency = 60
    } }

    let (takeScreenshot, uploadScreenshot, _) = spyScreenshots(store)
    let keylogging = spyKeylogging(store, keystrokes: mock(
      returning: [[.mock]],
      then: .some(nil)
    ))

    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .seconds(60 * 5)) // <- to heartbeat
    await expect(takeScreenshot.invocations.count).toEqual(5)
    await expect(uploadScreenshot.invocations.count).toEqual(5)
    await expect(keylogging.upload.invocations.count).toEqual(1)

    // send disconnect
    await store.send(.adminAuthenticated(.adminWindow(.webview(.reconnectUserClicked))))
    await bgQueue.advance(by: .seconds(60 * 5)) // <- to heartbeat

    // no new invocations for any of these...
    await expect(takeScreenshot.invocations.count).toEqual(5)
    await expect(uploadScreenshot.invocations.count).toEqual(5)
    await expect(keylogging.upload.invocations.count).toEqual(1)
  }

  func testMonitoringItemsBufferedForLaterUploadWhenNoConnection() async {
    let (store, bgQueue) = AppReducer.testStore()
    store.deps.network.isConnected = { false } // <-- no internet connection
    let (takeScreenshot, uploadScreenshot, _) = spyScreenshots(store)
    let takePendingScreenshots = mock(returning: [[
      (Data(), 999, 600, Date.epoch),
      (Data(), 999, 600, Date.epoch),
      (Data(), 999, 600, Date.epoch),
    ]])
    store.deps.monitoring.takePendingScreenshots = takePendingScreenshots.fn

    let keylogging = spyKeylogging(store, keystrokes: mock(
      returning: [[.mock]],
      then: .some(nil)
    ))

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.keyloggingEnabled = true
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotSize = 1000
      $0.user?.screenshotFrequency = 60
    } }

    store.deps.api.refreshRules = { _ in throw TestErr("stop launch refresh") }
    await store.send(.application(.didFinishLaunching))
    await bgQueue.advance(by: .seconds(60))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))
    await bgQueue.advance(by: .seconds(60))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))

    // we took 2 screenshots, but didn't upload them, b/c no connection
    await expect(takeScreenshot.invocations).toEqual([1000, 1000])
    await expect(uploadScreenshot.invoked).toEqual(false)
    await expect(takePendingScreenshots.invoked).toEqual(false)

    // and we skip uploading keystrokes
    await store.send(.heartbeat(.everyFiveMinutes))
    await expect(keylogging.upload.invocations.count).toEqual(0)
    await expect(keylogging.take.invocations).toEqual(0)

    // internet comes back on...
    store.deps.network.isConnected = { true }
    await bgQueue.advance(by: .seconds(60))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))
    await expect(takeScreenshot.invocations).toEqual([1000, 1000, 1000])
    // ...so we upload the buffered screenshots
    await expect(uploadScreenshot.invocations.count).toEqual(3)
    await expect(takePendingScreenshots.invocations).toEqual(1)

    // and we upload buffered keystrokes
    await store.send(.heartbeat(.everyFiveMinutes))
    await expect(keylogging.upload.invocations.count).toEqual(1)
    await expect(keylogging.take.invocations).toEqual(1)
  }

  // helpers

  func spyScreenshots(_ store: TestStoreOf<AppReducer>)
    -> (
      takeScreenshot: Spy<Void, Int>,
      uploadScreenshot: Spy4<URL, Data, Int, Int, Date>,
      takePendingScreenshots: Mock<[(Data, Int, Int, Date)], Int>
    ) {
    let takeScreenshot = spy(on: Int.self, returning: ())
    store.deps.monitoring.takeScreenshot = takeScreenshot.fn
    let takePendingScreenshots = mock(always: [(Data(), 999, 600, Date.epoch)])
    store.deps.monitoring.takePendingScreenshots = takePendingScreenshots.fn

    let uploadScreenshot = spy4(
      on: (Data.self, Int.self, Int.self, Date.self),
      returning: URL(string: "/uploaded.png")!
    )
    store.deps.api.uploadScreenshot = uploadScreenshot.fn
    return (takeScreenshot, uploadScreenshot, takePendingScreenshots)
  }

  struct Keylogging {
    var start: Mock<Void, Int>
    var stop: Mock<Void, Int>
    var take: Mock<CreateKeystrokeLines.Input?, Int>
    var upload: Spy<Void, CreateKeystrokeLines.Input>
  }

  func spyKeylogging(
    _ store: TestStoreOf<AppReducer>,
    keystrokes take: Mock<CreateKeystrokeLines.Input?, Int> = mock(always: [.mock])
  ) -> Keylogging {
    let start = mock(always: ())
    store.deps.monitoring.startLoggingKeystrokes = start.fn
    let stop = mock(always: ())
    store.deps.monitoring.stopLoggingKeystrokes = stop.fn
    store.deps.monitoring.takePendingKeystrokes = take.fn
    let upload = spy(on: CreateKeystrokeLines.Input.self, returning: ())
    store.deps.api.createKeystrokeLines = upload.fn
    return Keylogging(start: start, stop: stop, take: take, upload: upload)
  }
}
