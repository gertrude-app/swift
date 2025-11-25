import Dependencies
import Gertie
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App
@testable import ClientInterfaces

final class MonitoringFeatureTests: XCTestCase {
  @MainActor
  func testLoadingUserStateOnLaunchStartsMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.keyloggingEnabled = true
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotSize = 1000
      $0.user?.screenshotFrequency = 60
    } }

    let (takeScreenshot, uploadScreenshot, takePendingScreenshots) = self.spyScreenshots(store)
    let keylogging = self.spyKeylogging(store)

    store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }

    await store.send(.application(.didFinishLaunching))

    await expect(keylogging.start.called).toEqual(true)

    await bgQueue.advance(by: .seconds(60))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))
    await expect(takeScreenshot.calls).toEqual([1000])
    await expect(uploadScreenshot.calls).toEqual([.init(Data(), 999, 600, false, .epoch)])
    await expect(takePendingScreenshots.calls.count).toEqual(1)

    await bgQueue.advance(by: .seconds(59))
    await expect(uploadScreenshot.calls).toEqual([.init(Data(), 999, 600, false, .epoch)])
    await expect(takeScreenshot.calls).toEqual([1000])

    await bgQueue.advance(by: .seconds(1))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))
    await expect(takeScreenshot.calls).toEqual([1000, 1000])
    await expect(takePendingScreenshots.calls.count).toEqual(2)
    await expect(uploadScreenshot.calls).toEqual([
      .init(Data(), 999, 600, false, .epoch),
      .init(Data(), 999, 600, false, .epoch),
    ])

    await expect(keylogging.take.called).toEqual(false)
    await expect(keylogging.upload.called).toEqual(false)
    await bgQueue.advance(by: .seconds(60 * 3))
    await expect(keylogging.take.called).toEqual(true)
    await expect(keylogging.upload.called).toEqual(true)
  }

  @MainActor
  func testMonitoringItemsRecordFilterSuspensionState() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.keyloggingEnabled = true
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotSize = 1000
      $0.user?.screenshotFrequency = 60
    } }

    let (_, uploadScreenshot, _) = self.spyScreenshots(store)
    let keylogging = self.spyKeylogging(store)
    store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }

    await store.send(.application(.didFinishLaunching)) // start heartbeat

    // first screenshot NOT taken during filter suspension
    await bgQueue.advance(by: .seconds(60))
    await expect(uploadScreenshot.calls).toEqual([.init(Data(), 999, 600, false, .epoch)])
    await expect(keylogging.commit.called).toEqual(false)
    await expect(keylogging.take.called).toEqual(false)

    // now, they get a filter suspension
    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .accepted(duration: 300, extraMonitoring: nil),
      comment: nil,
    ))))

    // suspending the filter triggers flushing of all pending screenshots as "not during suspension"
    await expect(keylogging.commit.calls).toEqual([false])
    await expect(keylogging.take.calls.count).toEqual(1)
    await expect(keylogging.upload.calls).toEqual([[.mock]])

    await bgQueue.advance(by: .seconds(60))
    await expect(uploadScreenshot.calls).toEqual([
      .init(Data(), 999, 600, false, .epoch),
      .init(Data(), 999, 600, true, .epoch), // <-- second screenshot taken during suspension
    ])

    await store.send(.menuBar(.resumeFilterClicked))

    await expect(keylogging.commit.calls).toEqual([
      false,
      true, // <-- resuming filter commits pending screenshots as "during suspension"
    ])
    await expect(keylogging.take.calls.count).toEqual(2)
    await expect(keylogging.upload.calls.count).toEqual(2)

    await bgQueue.advance(by: .seconds(60))
    await expect(uploadScreenshot.calls).toEqual([
      .init(Data(), 999, 600, false, .epoch),
      .init(Data(), 999, 600, true, .epoch),
      .init(Data(), 999, 600, false, .epoch), // <-- third screenshot after resuming
    ])

    await bgQueue.advance(by: .seconds(120)) // <-- advance to 5 min heartbeat
    await expect(keylogging.commit.calls).toEqual([
      false,
      true,
      false, // <-- back to not suspended
    ])
    await expect(keylogging.take.calls.count).toEqual(3)
    await expect(keylogging.upload.calls.count).toEqual(3)
  }

  @MainActor
  func testCommittingAndTakingKeystrokesFromMonitorClass() {
    let monitor = KeystrokeMonitor()
    monitor.receive(keystroke: "l", from: "Xcode")
    monitor.receive(keystroke: "o", from: "Xcode")
    monitor.receive(keystroke: "l", from: "Xcode")
    monitor.commitPendingKeystrokes(filterSuspended: false)
    monitor.receive(keystroke: "h", from: "Xcode")
    monitor.receive(keystroke: "i", from: "Xcode")
    monitor.commitPendingKeystrokes(filterSuspended: true)
    let pending = monitor.takeKeystrokes().map {
      CreateKeystrokeLines.KeystrokeLineInput(
        appName: $0.appName,
        line: $0.line,
        filterSuspended: $0.filterSuspended,
        time: .epoch,
      )
    }
    expect(pending).toEqual([
      .init(appName: "Xcode", line: "lol", filterSuspended: false, time: .epoch),
      .init(appName: "Xcode", line: "hi", filterSuspended: true, time: .epoch),
    ])
  }

  @MainActor
  func testAddKeyloggingAndScreenshotsToUnMonitoredDuringSuspension() async {
    await withDependencies {
      $0.date = .constant(.epoch) // for testing menu bar state
    } operation: {
      let (store, bgQueue) = AppReducer.testStore()
      store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }
      let (takeScreenshot, uploadScreenshot, _) = self.spyScreenshots(store)
      let keylogging = self.spyKeylogging(store)

      // user is NOT monitored...
      store.deps.storage.loadPersistentState = { .mock { $0.user = .notMonitored } }

      await store.send(.application(.didFinishLaunching))
      await store.skipReceivedActions()

      // without extra monitoring, no monitoring happens
      await bgQueue.advance(by: .seconds(60 * 5)) // <- to heartbeat
      await expect(keylogging.start.calls.count).toEqual(0)
      await expect(takeScreenshot.called).toEqual(false)
      await expect(uploadScreenshot.called).toEqual(false)
      await expect(keylogging.stop.calls.count).toEqual(1) // called on initial configure

      if case .connected(let connectedState) = store.state.menuBarView {
        expect(connectedState.recordingScreen).toEqual(false)
        expect(connectedState.recordingKeystrokes).toEqual(false)
      } else {
        XCTFail("expected menubar state to be .connected")
      }

      // now they receive a filter suspension with extra monitoring
      await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
        id: .init(),
        decision: .accepted(
          duration: 60 * 4,
          extraMonitoring: .addKeyloggingAndSetScreenshotFreq(60),
        ),
        comment: nil,
      )))) {
        $0.monitoring.suspensionMonitoring = .init(
          keyloggingEnabled: true,
          screenshotsEnabled: true,
          screenshotSize: 1000,
          screenshotFrequency: 60,
        )
      }

      await expect(keylogging.start.calls.count).toEqual(1)
      await expect(keylogging.stop.calls.count).toEqual(1)

      if case .connected(let connectedState) = store.state.menuBarView {
        expect(connectedState.recordingScreen).toEqual(true)
        expect(connectedState.recordingKeystrokes).toEqual(true)
      } else {
        XCTFail("expected menubar state to be .connected")
      }

      // simulate the filter sends a message when the suspension is over
      await bgQueue.advance(by: .seconds(60 * 4))
      await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502))))

      await store.receive(.delegate(.filterSuspendedChanged(was: true, is: false))) {
        $0.monitoring.suspensionMonitoring = nil
      }

      await expect(keylogging.stop.calls.count).toEqual(2) // keylogging stopped
      await expect(keylogging.start.calls.count).toEqual(1) // and didn't restart

      await bgQueue.advance(by: .seconds(60 * 5)) // <-- to well past suspension end...

      // ...but we've still only taken the 4 screenshots during suspension
      await expect(takeScreenshot.calls.count).toEqual(4)
      await expect(uploadScreenshot.calls.count).toEqual(4)

      await store.send(.application(.didFinishLaunching))
    }
  }

  @MainActor
  func testAddOnlyKeyloggingToUnMonitoredDuringSuspension() async {
    let (store, bgQueue) = AppReducer.testStore()
    store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }
    let (takeScreenshot, _, _) = self.spyScreenshots(store)
    let keylogging = self.spyKeylogging(store)

    // user is NOT monitored...
    store.deps.storage.loadPersistentState = { .mock { $0.user = .notMonitored } }

    await store.send(.application(.didFinishLaunching))

    // without extra monitoring, no monitoring happens
    await bgQueue.advance(by: .seconds(60 * 5)) // <- to heartbeat
    await expect(keylogging.start.called).toEqual(false)
    await expect(takeScreenshot.called).toEqual(false)
    await expect(keylogging.stop.calls.count).toEqual(1) // called on initial configure

    // now they receive a filter suspension with extra monitoring, adding only keylogging
    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .accepted(duration: 60 * 4, extraMonitoring: .addKeylogging),
      comment: nil,
    )))) {
      $0.monitoring.suspensionMonitoring = .init(
        keyloggingEnabled: true,
        screenshotsEnabled: false,
        screenshotSize: 1000,
        screenshotFrequency: 60,
      )
    }

    await expect(keylogging.start.calls.count).toEqual(1) // <-- keylogging started
    await expect(keylogging.stop.calls.count).toEqual(1)

    // simulate the filter sends a message when the suspension is over
    await bgQueue.advance(by: .seconds(60 * 4))
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502))))

    await expect(keylogging.stop.calls.count).toEqual(2) // keylogging stopped
    await expect(keylogging.start.calls.count).toEqual(1) // and didn't restart

    await bgQueue.advance(by: .seconds(60 * 5)) // <-- to well past suspension end...

    // ...but we've still never taken screenshots
    await expect(takeScreenshot.called).toEqual(false)

    await store.send(.application(.didFinishLaunching))
  }

  @MainActor
  func testIncreaseScreenshotsDuringSuspension() async {
    let (store, bgQueue) = AppReducer.testStore()
    store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }
    let (takeScreenshot, _, _) = self.spyScreenshots(store)
    let keylogging = self.spyKeylogging(store)

    // user already has screenshots
    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.keyloggingEnabled = false
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotFrequency = 60
    } }

    await store.send(.application(.didFinishLaunching))

    // without extra monitoring, no monitoring happens
    await bgQueue.advance(by: .seconds(60 * 5)) // <- to heartbeat
    await expect(keylogging.start.called).toEqual(false)
    await expect(takeScreenshot.calls.count).toEqual(5) // 1/minute

    // now they receive a filter suspension with increased screenshots
    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .accepted(duration: 60 * 2, extraMonitoring: .setScreenshotFreq(30)),
      comment: nil,
    )))) {
      $0.monitoring.suspensionMonitoring = .init(
        keyloggingEnabled: false,
        screenshotsEnabled: true,
        screenshotSize: 1000,
        screenshotFrequency: 30,
      )
    }

    // simulate the filter sends a message when the suspension is over
    await bgQueue.advance(by: .seconds(60 * 2))
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502))))

    // 5 in first 5 minutes, 4 more in next 2 minutes
    await expect(takeScreenshot.calls.count).toEqual(9)
    await expect(keylogging.start.called).toEqual(false)

    await bgQueue.advance(by: .seconds(60 * 5)) // five more minutes
    await expect(takeScreenshot.calls.count).toEqual(14) // back to normal

    await store.send(.application(.didFinishLaunching))
  }

  @MainActor
  func testHeartbeatFallbackCleansUpExpiredSuspensionMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()
    store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }
    let time = ControllingNow(starting: .epoch, with: bgQueue)
    store.deps.date = time.generator
    let (takeScreenshot, _, _) = self.spyScreenshots(store)
    let keylogging = self.spyKeylogging(store)

    // user is NOT monitored...
    store.deps.storage.loadPersistentState = { .mock { $0.user = .notMonitored } }

    await store.send(.application(.didFinishLaunching))

    // they receive a filter suspension with extra monitoring
    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .accepted(
        duration: 60 * 3,
        extraMonitoring: .setScreenshotFreq(60),
      ),
      comment: nil,
    )))) {
      $0.monitoring.suspensionMonitoring = .init(
        keyloggingEnabled: false,
        screenshotsEnabled: true,
        screenshotSize: 1000,
        screenshotFrequency: 60,
      )
    }

    // but 60 seconds past due, we've never received word from filter
    await time.advance(seconds: 60 * 4)
    // so the store still has the suspension config...
    expect(store.state.monitoring.suspensionMonitoring).not.toBeNil()
    // ...and we've taken 1 too many screenshots
    await expect(takeScreenshot.calls.count).toEqual(4)

    // but the 5 minute heartbeat should clean up
    await time.advance(seconds: 60)
    await store.receive(.heartbeat(.everyFiveMinutes)) {
      $0.monitoring.suspensionMonitoring = nil
    }

    await time.advance(seconds: 60 * 10) // far past cleanup...

    // and we've not taken another screenshot
    await expect(takeScreenshot.calls.count).toEqual(4)
    await expect(keylogging.start.called).toEqual(false)

    await store.send(.application(.didFinishLaunching))
  }

  @MainActor
  func testReusesLastExtraMonitoringForAdminGrantedSuspensions() async {
    let (store, bgQueue) = AppReducer.testStore()
    store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }
    store.deps.storage.loadPersistentState = { .mock { $0.user = .notMonitored } }
    let (takeScreenshot, _, _) = self.spyScreenshots(store)

    await store.send(.application(.didFinishLaunching))

    // now they receive a filter suspension with increased screenshots
    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .accepted(duration: 60 * 2, extraMonitoring: .setScreenshotFreq(30)),
      comment: nil,
    ))))

    // simulate the filter sends a message when the suspension is over
    await bgQueue.advance(by: .seconds(60 * 2))
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502))))
    await store.skipReceivedActions()
    await expect(takeScreenshot.calls.count).toEqual(4) // 2/minute

    // now the admin grants a suspension...
    await store.send(
      .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(durationInSeconds: 120)))),
    ) {
      $0.monitoring.suspensionMonitoring = .init(
        keyloggingEnabled: false,
        screenshotsEnabled: true, // <-- from prev suspension extra monitoring
        screenshotSize: 1000,
        screenshotFrequency: 30, // < -- and this
      )
    }

    // simulate the filter sends a message when the suspension is over
    await bgQueue.advance(by: .seconds(60 * 2))
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502))))
    await store.skipReceivedActions()
    await expect(takeScreenshot.calls.count).toEqual(8)

    // now they receive a filter suspension with NO extra monitoring
    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .accepted(duration: 60 * 2, extraMonitoring: nil),
      comment: nil,
    ))))

    // simulate the filter sends a message when the suspension is over
    await bgQueue.advance(by: .seconds(60 * 2))
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502))))
    await store.skipReceivedActions()
    await expect(takeScreenshot.calls.count).toEqual(8) // still 8

    // now the admin grants another suspension...
    await store.send(
      .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(durationInSeconds: 120)))),
    ) {
      // ...and we re-use the fact that the last suspension had no extra monitoring
      $0.monitoring.suspensionMonitoring = nil
    }

    await store.send(.application(.didFinishLaunching))
  }

  @MainActor
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

    store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }
    let (takeScreenshot, uploadScreenshot, _) = self.spyScreenshots(store)
    let keylogging = self.spyKeylogging(store, keystrokes: mock(
      returning: [nil],
      then: [.mock],
    ))

    await store.send(.application(.didFinishLaunching))

    // without permissions, no monitoring happens
    await expect(keylogging.stop.called).toEqual(true)
    await expect(keylogging.start.called).toEqual(false)
    await bgQueue.advance(by: .seconds(60 * 5)) // <- to heartbeat
    await expect(keylogging.upload.called).toEqual(false)
    await expect(takeScreenshot.called).toEqual(false)
    await expect(uploadScreenshot.called).toEqual(false)

    // but, simulate permissions fixed...
    store.deps.monitoring.screenRecordingPermissionGranted = { true }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { true }

    // ...and send a health-check recheck event...
    await store.send(.adminWindow(.webview(.healthCheck(action: .recheckClicked))))

    // ...and now monitoring should start up
    await expect(keylogging.start.called).toEqual(true)
    await bgQueue.advance(by: .seconds(60 * 5)) // <- to heartbeat
    await expect(keylogging.upload.called).toEqual(true)
    await expect(takeScreenshot.called).toEqual(true)
    await expect(uploadScreenshot.called).toEqual(true)
  }

  @MainActor
  func testPendingKeystrokesRestoredIfApiRequestFails() async {
    let (store, _) = AppReducer.testStore()
    _ = self.spyKeylogging(store)
    let restore = spy(on: CreateKeystrokeLines.Input.self, returning: ())
    store.deps.monitoring.restorePendingKeystrokes = restore.fn
    store.deps.api.createKeystrokeLines = { _ in throw TestErr("oh noes!") }
    await store.send(.heartbeat(.everyFiveMinutes))
    // pending keystrokes are restored
    await expect(restore.calls).toEqual([[.mock]])
  }

  @MainActor
  func testLoadingUserStateOnLaunchNoMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.screenshotsEnabled = false
      $0.user?.keyloggingEnabled = false
    } }

    store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }
    store.deps.monitoring.takeScreenshot = { _ in fatalError() }
    store.deps.api.uploadScreenshot = { _ in fatalError() }
    let keylogging = self.spyKeylogging(store, keystrokes: mock(always: nil))

    await store.send(.application(.didFinishLaunching))
    await bgQueue.advance(by: .seconds(600))
    await expect(keylogging.take.called).toEqual(true) // we always check
    await expect(keylogging.upload.called).toEqual(false)
  }

  @MainActor
  func testLoadingNilUserOnLaunchNoMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }
    store.deps.monitoring.takeScreenshot = { _ in fatalError() }
    store.deps.api.uploadScreenshot = { _ in fatalError() }
    let keylogging = self.spyKeylogging(store, keystrokes: mock(always: nil))
    store.deps.storage.loadPersistentState = { .mock {
      $0.user = nil // <-- no user!
    } }

    await store.send(.application(.didFinishLaunching))
    await bgQueue.advance(by: .seconds(600)) // <-- no fatal error, heartbeat not running
    await expect(keylogging.take.called).toEqual(false)
    await expect(keylogging.upload.called).toEqual(false)
  }

  @MainActor
  func testGettingNewRulesStartsMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .empty {
      $0.user?.screenshotsEnabled = false
      $0.user?.keyloggingEnabled = false
    } }

    // initial launch refresh, no screenshots
    store.deps.api.checkIn = { _ in .empty {
      $0.userData.screenshotsEnabled = false
      $0.userData.keyloggingEnabled = false
    } }
    let (takeScreenshot, uploadScreenshot, _) = self.spyScreenshots(store)
    let keylogging = self.spyKeylogging(store, keystrokes: mock(
      returning: [nil],
      then: [.mock],
    ))

    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .seconds(300))
    await expect(takeScreenshot.called).toEqual(false)
    await expect(uploadScreenshot.called).toEqual(false)
    await expect(keylogging.upload.called).toEqual(false)

    // simulate new rules came in, from user click
    await store.send(.checkIn(result: .success(.empty {
      $0.userData.keyloggingEnabled = true // <- enabled
      $0.userData.screenshotsEnabled = true // <- enabled
      $0.userData.screenshotFrequency = 120 // <- every 2 minutes
      $0.userData.screenshotSize = 1200
    }), reason: .heartbeat))

    await bgQueue.advance(by: .seconds(60))
    await expect(takeScreenshot.called).toEqual(false)
    await expect(uploadScreenshot.called).toEqual(false)
    await bgQueue.advance(by: .seconds(60))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))
    await expect(takeScreenshot.calls).toEqual([1200])
    await expect(uploadScreenshot.calls).toEqual([.init(Data(), 999, 600, false, .epoch)])
    await bgQueue.advance(by: .seconds(60 * 3)) // advance to heartbeat
    await Task.repeatYield()
    await expect(keylogging.upload.called).toEqual(true)
  }

  @MainActor
  func testGettingNewRulesStopsMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.keyloggingEnabled = true
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotSize = 700
      $0.user?.screenshotFrequency = 60
    } }

    store.deps.api.checkIn = { _ in .mock {
      $0.userData.keyloggingEnabled = true
      $0.userData.screenshotsEnabled = true
      $0.userData.screenshotSize = 700
      $0.userData.screenshotFrequency = 60
    } }

    let (takeScreenshot, uploadScreenshot, _) = self.spyScreenshots(store)
    let keylogging = self.spyKeylogging(store, keystrokes: mock(
      returning: [[.mock]],
      then: .some(nil),
    ))

    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .seconds(60))
    await Task.repeatYield()
    await expect(takeScreenshot.calls).toEqual([700])
    await expect(uploadScreenshot.calls).toEqual([.init(Data(), 999, 600, false, .epoch)])
    await bgQueue.advance(by: .seconds(60 * 4)) // <- to heartbeat
    await expect(keylogging.upload.calls.count).toEqual(1)
    await expect(takeScreenshot.calls.count).toEqual(5)
    await expect(uploadScreenshot.calls.count).toEqual(5)

    // simulate new rules came in, from user click
    await store.send(.checkIn(result: .success(.mock {
      $0.userData.keyloggingEnabled = false // <-- disabled
      $0.userData.screenshotsEnabled = false // <-- disabled
    }), reason: .heartbeat))

    await bgQueue.advance(by: .seconds(60 * 5))

    // no new calls for any of these...
    await expect(keylogging.upload.calls.count).toEqual(1)
    await expect(takeScreenshot.calls.count).toEqual(5)
    await expect(uploadScreenshot.calls.count).toEqual(5)
  }

  @MainActor
  func testConnectingUserStartsMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }
    store.deps.storage.loadPersistentState = { .init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .stable,
      filterVersion: "1.0.0",
      user: nil, // <-- no user
      resumeOnboarding: nil,
    ) }

    let (takeScreenshot, uploadScreenshot, _) = self.spyScreenshots(store)
    let keylogging = self.spyKeylogging(store)

    await store.send(.application(.didFinishLaunching))
    await expect(takeScreenshot.calls.count).toEqual(0)
    await expect(uploadScreenshot.calls.count).toEqual(0)
    await expect(keylogging.upload.calls.count).toEqual(0)

    // simulate user connect
    await store.send(.history(.userConnection(.connect(.success(.mock {
      $0.keyloggingEnabled = true
      $0.screenshotsEnabled = true
      $0.screenshotFrequency = 45
      $0.screenshotSize = 800
    })))))

    // now we start getting screenshots, and keystrokes
    await bgQueue.advance(by: .seconds(60))
    await expect(takeScreenshot.calls).toEqual([800])
    await expect(uploadScreenshot.calls).toEqual([.init(Data(), 999, 600, false, .epoch)])
    await bgQueue.advance(by: .seconds(60 * 4)) // <- to heartbeat
    await Task.repeatYield()
    await expect(keylogging.upload.calls.count).toEqual(1)
  }

  @MainActor
  func testDisconnectingUserStopsMonitoring() async {
    let (store, bgQueue) = AppReducer.testStore()

    store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }
    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.keyloggingEnabled = true
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotFrequency = 60
    } }

    let (takeScreenshot, uploadScreenshot, _) = self.spyScreenshots(store)
    let keylogging = self.spyKeylogging(store, keystrokes: mock(
      returning: [[.mock]],
      then: .some(nil),
    ))

    await store.send(.application(.didFinishLaunching))

    await bgQueue.advance(by: .seconds(60 * 5)) // <- to heartbeat
    await expect(takeScreenshot.calls.count).toEqual(5)
    await expect(uploadScreenshot.calls.count).toEqual(5)
    await expect(keylogging.upload.calls.count).toEqual(1)

    // send disconnect
    await store.send(.adminAuthed(.adminWindow(.webview(.disconnectUserClicked))))
    await bgQueue.advance(by: .seconds(60 * 5)) // <- to heartbeat

    // no new calls for any of these...
    await expect(takeScreenshot.calls.count).toEqual(5)
    await expect(uploadScreenshot.calls.count).toEqual(5)
    await expect(keylogging.upload.calls.count).toEqual(1)
  }

  @MainActor
  func testMonitoringItemsBufferedForLaterUploadWhenNoConnection() async {
    let (store, bgQueue) = AppReducer.testStore()
    store.deps.network.isConnected = { false } // <-- no internet connection
    let (takeScreenshot, uploadScreenshot, _) = self.spyScreenshots(store)
    let takePendingScreenshots = mock(returning: [[
      (Data(), 999, 600, Date.epoch),
      (Data(), 999, 600, Date.epoch),
      (Data(), 999, 600, Date.epoch),
    ]])
    store.deps.monitoring.takePendingScreenshots = takePendingScreenshots.fn

    let keylogging = self.spyKeylogging(store, keystrokes: mock(
      returning: [[.mock]],
      then: .some(nil),
    ))

    store.deps.storage.loadPersistentState = { .mock {
      $0.user?.keyloggingEnabled = true
      $0.user?.screenshotsEnabled = true
      $0.user?.screenshotSize = 1000
      $0.user?.screenshotFrequency = 60
    } }

    store.deps.api.checkIn = { _ in throw TestErr("stop launch checkin") }
    await store.send(.application(.didFinishLaunching))
    await bgQueue.advance(by: .seconds(60))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))
    await bgQueue.advance(by: .seconds(60))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))

    // we took 2 screenshots, but didn't upload them, b/c no connection
    await expect(takeScreenshot.calls).toEqual([1000, 1000])
    await expect(uploadScreenshot.called).toEqual(false)
    await expect(takePendingScreenshots.called).toEqual(false)

    // and we skip uploading keystrokes
    await store.send(.heartbeat(.everyFiveMinutes))
    await expect(keylogging.upload.calls.count).toEqual(0)
    await expect(keylogging.take.calls.count).toEqual(0)

    // internet comes back on...
    store.deps.network.isConnected = { true }
    await bgQueue.advance(by: .seconds(60))
    await store.receive(.monitoring(.timerTriggeredTakeScreenshot))
    await expect(takeScreenshot.calls).toEqual([1000, 1000, 1000])
    // ...so we upload the buffered screenshots
    await expect(uploadScreenshot.calls.count).toEqual(3)
    await expect(takePendingScreenshots.calls.count).toEqual(1)

    // and we upload buffered keystrokes
    await store.send(.heartbeat(.everyFiveMinutes))
    await expect(keylogging.upload.calls.count).toEqual(1)
    await expect(keylogging.take.calls.count).toEqual(1)
  }

  @MainActor
  func testNumMacosUsersSecurityEvent() async throws {
    let key = "numMacOsUsers"
    let (store, _) = AppReducer.testStore()
    let getInt = spySync(on: String.self, returning: [0, 2, 2], then: 3)
    store.deps.api.logSecurityEvent = unimplemented("should not be called")
    store.deps.userDefaults.getInt = getInt.fn
    store.deps.device.listMacOSUsers = { [.dad, .franny] }

    let setNumCalls = LockIsolated<[Both<String, Int>]>([])
    store.deps.userDefaults.setInt = { key, value in
      setNumCalls.withValue { $0.append(.init(key, value)) }
    }

    // first check, records current number
    await store.send(.heartbeat(.everyTwentyMinutes))
    expect(getInt.calls).toEqual([key])
    expect(setNumCalls.value).toEqual([.init(key, 2)])

    // next time we check, we get `2`, which is same, so nothing to do
    await store.send(.heartbeat(.everyTwentyMinutes))
    expect(getInt.calls).toEqual([key, key])
    expect(setNumCalls.value).toEqual([.init(key, 2)])

    // third time, we now see `3` users so emit a security event and update
    store.deps.device.listMacOSUsers = { [
      .dad,
      .franny,
      .init(id: 503, name: "suspicious", type: .admin), // <-- new user
    ] }
    let securityEvent = spy2(on: (LogSecurityEvent.Input.self, UUID?.self), returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn

    await store.send(.heartbeat(.everyTwentyMinutes))
    expect(getInt.calls).toEqual([key, key, key])
    expect(setNumCalls.value).toEqual([.init(key, 2), .init(key, 3)])
    await expect(securityEvent.calls).toEqual([Both(.init(.newMacOsUserCreated), nil)])

    // removing a user does not emit a security event
    store.deps.device.listMacOSUsers = { [.dad, .franny] }
    store.deps.api.logSecurityEvent = unimplemented("should not be called")
    await store.send(.heartbeat(.everyTwentyMinutes))
    expect(getInt.calls).toEqual([key, key, key, key])
    expect(setNumCalls.value).toEqual([.init(key, 2), .init(key, 3), .init(key, 2)])
  }

  // helpers

  func spyScreenshots(_ store: TestStoreOf<AppReducer>) -> (
    takeScreenshot: Spy<Void, Int>,
    uploadScreenshot: Spy<URL, ApiClient.UploadScreenshotData>,
    takePendingScreenshots: Mock<[(Data, Int, Int, Date)]>,
  ) {
    let takeScreenshot = spy(on: Int.self, returning: ())
    store.deps.monitoring.takeScreenshot = takeScreenshot.fn
    let takePendingScreenshots = mock(always: [(Data(), 999, 600, Date.epoch)])
    store.deps.monitoring.takePendingScreenshots = takePendingScreenshots.fn

    let uploadScreenshot = spy(
      on: ApiClient.UploadScreenshotData.self,
      returning: URL(string: "/uploaded.png")!,
    )
    store.deps.api.uploadScreenshot = uploadScreenshot.fn
    return (takeScreenshot, uploadScreenshot, takePendingScreenshots)
  }

  struct Keylogging {
    var start: Mock<Void>
    var stop: Mock<Void>
    var commit: Spy<Void, Bool>
    var take: Mock<CreateKeystrokeLines.Input?>
    var upload: Spy<Void, CreateKeystrokeLines.Input>
  }

  func spyKeylogging(
    _ store: TestStoreOf<AppReducer>,
    keystrokes take: Mock<CreateKeystrokeLines.Input?> = mock(always: [.mock]),
  ) -> Keylogging {
    let start = mock(always: ())
    store.deps.monitoring.startLoggingKeystrokes = start.fn
    let stop = mock(always: ())
    store.deps.monitoring.stopLoggingKeystrokes = stop.fn
    store.deps.monitoring.takePendingKeystrokes = take.fn
    let upload = spy(on: CreateKeystrokeLines.Input.self, returning: ())
    store.deps.api.createKeystrokeLines = upload.fn
    let commit = spy(on: Bool.self, returning: ())
    store.deps.monitoring.commitPendingKeystrokes = commit.fn
    return Keylogging(start: start, stop: stop, commit: commit, take: take, upload: upload)
  }
}

extension ApiClient.UploadScreenshotData {
  init(
    _ image: Data,
    _ width: Int,
    _ height: Int,
    _ filterSuspended: Bool = false,
    _ createdAt: Date,
  ) {
    self.init(
      image: image,
      width: width,
      height: height,
      filterSuspended: filterSuspended,
      createdAt: createdAt,
    )
  }
}
