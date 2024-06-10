import ComposableArchitecture
import Core
import Gertie
import MacAppRoute
import TaggedTime
import TestSupport
import XCTest
import XExpect

@testable import App

@MainActor final class FilterFeatureTests: XCTestCase {
  func testResumeSuspension() async {
    let (store, _) = AppReducer.testStore {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 90)
      $0.browsers = [.name("Arc")]
    }

    let filterNotify = mock(once: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.endFilterSuspension = filterNotify.fn
    let notification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = notification.fn
    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()
    let quitBrowsers = spy(on: [BrowserMatch].self, returning: ())
    store.deps.device.quitBrowsers = quitBrowsers.fn
    let securityEvent = spy(on: LogSecurityEvent.Input.self, returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn
    store.deps.storage.loadPersistentState = { .mock }

    await store.send(.menuBar(.resumeFilterClicked)) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await expect(filterNotify.invoked).toEqual(true)
    await expect(notification.invocations.value[0].a).toContain("browsers quitting soon")
    await expect(securityEvent.invocations).toEqual([.init(.filterSuspensionEndedEarly)])

    await scheduler.advance(by: 59)
    await expect(quitBrowsers.invoked).toEqual(false)
    await scheduler.advance(by: 1)
    await expect(quitBrowsers.invoked).toEqual(true)
    await expect(quitBrowsers.invocations).toEqual([[.name("Arc")]])
  }

  func testHeartbeatUpdatesFilterVersionIfPossible() async {
    let (store, _) = AppReducer.testStore {
      $0.appUpdates.installedVersion = "1.3.4"
      $0.filter.version = "1.3.3" // <-- out of date
    }

    let relaunch = mock(once: ())
    store.deps.app.relaunch = relaunch.fn
    store.deps.filterExtension.state = { .installedAndRunning }
    store.deps.filterXpc.checkConnectionHealth = { .success(()) }
    store.deps.filterXpc.requestAck = { .success(.init(
      randomInt: 333,
      version: "1.3.4", // <-- filter version from ack
      userId: 502,
      numUserKeys: 33
    )) }

    await store.send(.heartbeat(.everyFiveMinutes))

    await store.receive(.filter(.receivedVersion("1.3.4"))) {
      $0.filter.version = "1.3.4"
    }

    // we're not behind, so we don't relaunch
    await expect(relaunch.invoked).toEqual(false)
  }

  func testHeartbeatRelaunchesAppIfFilterAhead() async {
    let (store, _) = AppReducer.testStore {
      $0.appUpdates.installedVersion = "1.3.3" // <-- we're on "1.3.3"
      $0.filter.version = "1.3.3" // ... and we think the filter is too
    }

    store.deps.app = .testValue
    let stopWatcher = mock(once: ())
    store.deps.app.stopRelaunchWatcher = stopWatcher.fn
    let relaunch = mock(once: ())
    store.deps.app.relaunch = relaunch.fn
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    store.deps.filterExtension.state = { .installedAndRunning }
    store.deps.filterXpc.checkConnectionHealth = { .success(()) }
    store.deps.filterXpc.requestAck = { .success(.init(
      randomInt: 333,
      version: "1.3.4", // <-- but we get a new "ahead" filter version
      userId: 502,
      numUserKeys: 33
    )) }

    await store.send(.heartbeat(.everyFiveMinutes))

    // so we 1) update the state
    await store.receive(.filter(.receivedVersion("1.3.4"))) {
      $0.filter.version = "1.3.4"
    }
    // 2) store persistent state
    await expect(saveState.invocations.value).toHaveCount(1)
    // and 3) relaunch
    await expect(stopWatcher.invoked).toEqual(true)
    await expect(relaunch.invoked).toEqual(true)
  }

  func testManualAdminSuspensionLifecycle() async {
    let store = TestStore(initialState: AppReducer.State(appVersion: "1.0.0")) {
      AppReducer()
    }
    store.deps.websocket = .mock
    store.deps.device = .mock
    store.deps.date = .constant(Date(timeIntervalSince1970: 0))
    store.deps.storage.loadPersistentState = { .mock }
    let suspendFilter = spy(on: Seconds<Int>.self, returning: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.suspendFilter = suspendFilter.fn
    let resumeFilter = mock(returning: [Result<Void, XPCErr>.success(())])
    store.deps.filterXpc.endFilterSuspension = resumeFilter.fn
    let securityEvent = spy(on: LogSecurityEvent.Input.self, returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn

    expect(store.state.filter.currentSuspensionExpiration).toBeNil()
    await expect(suspendFilter.invoked).toEqual(false)

    // receive a manual suspension
    await store.send(
      .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(durationInSeconds: 30))))
    ) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 30)
    }

    await expect(suspendFilter.invocations).toEqual([30])
    await expect(resumeFilter.invoked).toEqual(false)
    await expect(securityEvent.invocations).toEqual([.init(.filterSuspensionGrantedByAdmin)])

    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()
    let showNotification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = showNotification.fn
    let quitBrowsers = spy(on: [BrowserMatch].self, returning: ())
    store.deps.device.quitBrowsers = quitBrowsers.fn

    // pretend 30 seconds passed and the filter notifies of suspension ending
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await scheduler.advance(by: .seconds(59))
    await expect(showNotification.invocations.value).toHaveCount(1)
    await expect(quitBrowsers.invocations.value.count).toEqual(0)
    await expect(showNotification.invocations.value[0].a).toContain("browsers quitting soon")

    // after 60 seconds pass, we quit the browsers
    await scheduler.advance(by: .seconds(1))
    await expect(quitBrowsers.invocations.value.count).toEqual(1)
  }

  func testFilterSuspensionCanBeExtendedByReceivingAnother() async {
    let (store, scheduler) = AppReducer.testStore()
    let time = ControllingNow(starting: .epoch, with: scheduler)
    store.deps.date = time.generator
    let showNotification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = showNotification.fn
    let suspendFilter = spy(on: Seconds<Int>.self, returning: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.suspendFilter = suspendFilter.fn
    let quitBrowsers = spy(on: [BrowserMatch].self, returning: ())
    store.deps.device.quitBrowsers = quitBrowsers.fn

    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided(
      decision: .accepted(duration: 120, extraMonitoring: nil),
      comment: "yup!"
    )))) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 120)
    }

    await expect(suspendFilter.invocations).toEqual([120])
    await time.advance(seconds: 100)

    // they get ANOTHER suspension before the first one has expired
    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided(
      decision: .accepted(duration: 120, extraMonitoring: nil),
      comment: "here's another one for ya!"
    )))) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 100 + 120)
    }

    await expect(suspendFilter.invocations).toEqual([120, 120])

    // so far we've only showed them two "filter suspended", messages
    await expect(showNotification.invocations.value).toHaveCount(2)

    await time.advance(seconds: 40) // now move past first suspension expiration

    // and we haven't told them that the browsers are quitting
    await expect(showNotification.invocations.value).toHaveCount(2)
    await expect(quitBrowsers.invocations.value).toHaveCount(0)
    expect(store.state.filter.currentSuspensionExpiration).not.toBeNil()

    // now move past second suspension
    await time.advance(seconds: 100)
    await expect(showNotification.invocations.value).toHaveCount(2)
    await expect(quitBrowsers.invocations.value).toHaveCount(0)

    // simulate filter notifying that the suspension is over
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await expect(showNotification.invocations.value).toHaveCount(3)
    await expect(showNotification.invocations.value[2].a).toContain("browsers quitting soon")
    await expect(quitBrowsers.invocations.value).toHaveCount(1)
  }

  func testFilterSuspensionWebsocketLifecycle() async {
    let (store, _) = AppReducer.testStore()

    let showNotification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = showNotification.fn
    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()
    let suspendFilter = spy(on: Seconds<Int>.self, returning: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.suspendFilter = suspendFilter.fn
    let quitBrowsers = spy(on: [BrowserMatch].self, returning: ())
    store.deps.device.quitBrowsers = quitBrowsers.fn
    let resumeFilter = mock(returning: [Result<Void, XPCErr>.success(())])
    store.deps.filterXpc.endFilterSuspension = resumeFilter.fn

    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided(
      decision: .accepted(duration: 120, extraMonitoring: nil),
      comment: "yup!"
    )))) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 120)
    }

    await expect(suspendFilter.invocations).toEqual([120])
    await expect(showNotification.invocations.value).toHaveCount(1)
    await expect(showNotification.invocations.value[0].a).toContain("disabling filter")
    await expect(showNotification.invocations.value[0].b).toContain("yup!")
    await expect(showNotification.invocations.value[0].b).toContain("2 minutes from now")

    await scheduler.advance(by: .seconds(120))
    await expect(showNotification.invocations.value).toHaveCount(1)

    // simulate filter sending notice that suspension is ending
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await expect(showNotification.invocations.value).toHaveCount(2)
    await expect(showNotification.invocations.value[1].a).toContain("browsers quitting soon")

    await scheduler.advance(by: .seconds(59))
    await expect(quitBrowsers.invocations.value).toHaveCount(0)
    await scheduler.advance(by: .seconds(1))
    await expect(quitBrowsers.invocations.value).toHaveCount(1)

    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided(
      decision: .rejected,
      comment: "nope!"
    ))))

    await expect(showNotification.invocations.value).toHaveCount(3)
    await expect(showNotification.invocations.value[2].a).toContain("request DENIED")
    await expect(showNotification.invocations.value[2].b).toContain("nope!")
    await expect(suspendFilter.invocations).toEqual([120]) // <-- no new suspension sent

    // still handles legacy event (though this should never be received)
    await store.send(.websocket(.receivedMessage(.suspendFilter(for: 90, parentComment: "OK")))) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 90)
    }
    await expect(suspendFilter.invocations).toEqual([120, 90])
    await expect(showNotification.invocations.value).toHaveCount(4)
    await expect(showNotification.invocations.value[3].a).toContain("disabling filter")

    await scheduler.advance(by: .seconds(30))
    await expect(resumeFilter.invocations).toEqual(0)

    await store.send(.menuBar(.resumeFilterClicked)) {
      $0.filter.currentSuspensionExpiration = nil
    }
    await expect(resumeFilter.invocations).toEqual(1)
    await expect(showNotification.invocations.value).toHaveCount(5)
    await expect(showNotification.invocations.value[4].a).toContain("browsers quitting soon")

    await scheduler.advance(by: .seconds(59))
    await expect(quitBrowsers.invocations.value).toHaveCount(1)
    await scheduler.advance(by: .seconds(1))
    await expect(quitBrowsers.invocations.value).toHaveCount(2)
  }

  func testReceivingSuspensionDuring60SecondCountdownCancelsTimer() async {
    let (store, _) = AppReducer.testStore {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 30)
    }

    store.deps.date = .constant(Date(timeIntervalSince1970: 0))
    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()
    let showNotification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = showNotification.fn
    let quitBrowsers = spy(on: [BrowserMatch].self, returning: ())
    store.deps.device.quitBrowsers = quitBrowsers.fn

    // pretend 30 seconds passed and the filter notifies of suspension ending
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await expect(showNotification.invocations.value.count).toEqual(1)
    await expect(showNotification.invocations.value[0].a).toContain("browsers quitting soon")

    // 30 seconds from notification re: quitting browsers, dad sends another suspension!
    await scheduler.advance(by: .seconds(30))
    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided(
      decision: .accepted(duration: 120, extraMonitoring: nil),
      comment: nil
    )))) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 120)
    }

    // user notified of suspension
    await expect(showNotification.invocations.value.count).toEqual(2)
    await expect(showNotification.invocations.value[1].a).toContain("disabling filter")

    await scheduler.advance(by: .seconds(31))
    await expect(quitBrowsers.invocations.value).toHaveCount(0) // ...and browsers never quit!

    // now, receive a MANUAL suspension
    await store.send(
      .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(durationInSeconds: 30))))
    ) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 30)
    }

    // user notified of suspension
    await expect(showNotification.invocations.value.count).toEqual(3)
    await expect(showNotification.invocations.value[2].a).toContain("disabling filter")

    // pretend 30 seconds passed and the filter notifies of suspension ending
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    // user notified again that browsers will quit
    await expect(showNotification.invocations.value.count).toEqual(4)
    await expect(showNotification.invocations.value[3].a).toContain("browsers quitting soon")
    await scheduler.advance(by: .seconds(30))

    // now, receive a SECOND MANUAL suspension, which stops timer
    await store.send(
      .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(durationInSeconds: 30))))
    ) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 30)
    }

    await scheduler.advance(by: .seconds(31))
    await expect(quitBrowsers.invocations.value).toHaveCount(0) // browsers never quit
  }
}

extension LogSecurityEvent.Input {
  init(_ event: SecurityEvent.MacApp, _ detail: String? = nil) {
    self.init(
      deviceId: Persistent.State.mock.user!.deviceId,
      event: event.rawValue,
      detail: detail
    )
  }
}
