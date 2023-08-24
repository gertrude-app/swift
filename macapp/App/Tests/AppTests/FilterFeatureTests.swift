import ComposableArchitecture
import Core
import TaggedTime
import TestSupport
import XCTest
import XExpect

@testable import App

@MainActor final class FilterFeatureTests: XCTestCase {
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

    await store.send(.menuBar(.resumeFilterClicked)) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await expect(filterNotify.invoked).toEqual(true)
    await expect(notification.invocations.value[0].a).toContain("browsers quitting soon")

    await scheduler.advance(by: 59)
    await expect(quitBrowsers.invoked).toEqual(false)
    await scheduler.advance(by: 1)
    await expect(quitBrowsers.invoked).toEqual(true)
  }

  func testHeartbeatUpdatesFilterVersionIfPossible() async {
    let (store, _) = AppReducer.testStore {
      $0.filter.version = "1.3.3" // <-- out of date
    }

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
  }

  func testManualAdminSuspensionLifecycle() async {
    let store = TestStore(initialState: AppReducer.State()) { AppReducer() }
    store.deps.date = .constant(Date(timeIntervalSince1970: 0))
    let suspendFilter = spy(on: Seconds<Int>.self, returning: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.suspendFilter = suspendFilter.fn
    let resumeFilter = mock(returning: [Result<Void, XPCErr>.success(())])
    store.deps.filterXpc.endFilterSuspension = resumeFilter.fn

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

    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()
    let showNotification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = showNotification.fn
    let quitBrowsers = mock(returning: [()])
    store.deps.device.quitBrowsers = quitBrowsers.fn

    // pretend 30 seconds passed and the filter notifies of suspension ending
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await scheduler.advance(by: .seconds(59))
    await expect(showNotification.invocations.value).toHaveCount(1)
    await expect(quitBrowsers.invocations).toEqual(0)
    await expect(showNotification.invocations.value[0].a).toContain("browsers quitting soon")

    // after 60 seconds pass, we quit the browsers
    await scheduler.advance(by: .seconds(1))
    await expect(quitBrowsers.invocations).toEqual(1)
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
    let quitBrowsers = mock(returning: [()])
    store.deps.device.quitBrowsers = quitBrowsers.fn

    // pretend 30 seconds passed and the filter notifies of suspension ending
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await expect(showNotification.invocations.value.count).toEqual(1)
    await expect(showNotification.invocations.value[0].a).toContain("browsers quitting soon")

    await scheduler.advance(by: .seconds(30))

    // 30 seconds from quitting browsers, dad sends another suspension!
    await store.send(.websocket(.receivedMessage(.suspendFilter(for: 120, parentComment: nil)))) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 120)
    }

    // user notified of suspension
    await expect(showNotification.invocations.value.count).toEqual(2)
    await expect(showNotification.invocations.value[1].a).toContain("disabling filter")

    await scheduler.advance(by: .seconds(31))
    await expect(quitBrowsers.invocations).toEqual(0) // ...and browsers never quit!

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
    await expect(quitBrowsers.invocations).toEqual(0) // browsers never quit
  }
}
