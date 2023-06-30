import ComposableArchitecture
import Core
import TaggedTime
import TestSupport
import XCTest
import XExpect

@testable import App

@MainActor final class FilterFeatureTests: XCTestCase {
  func testManualAdminWindowSuspensionLifecycle() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())
    store.deps.date = .constant(Date(timeIntervalSince1970: 0))
    let suspendFilter = spy(on: Seconds<Int>.self, returning: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.suspendFilter = suspendFilter.fn
    let resumeFilter = mock(returning: [Result<Void, XPCErr>.success(())])
    store.deps.filterXpc.endFilterSuspension = resumeFilter.fn

    expect(store.state.filter.currentSuspensionExpiration).toBeNil()
    await expect(suspendFilter.invoked).toEqual(false)

    // receive a manual suspension
    await store.send(
      .adminAuthenticated(.adminWindow(.webview(.suspendFilterClicked(durationInSeconds: 30))))
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
    await expect(showNotification.invocations.count).toEqual(1)
    await expect(quitBrowsers.invocations).toEqual(0)
    await expect(showNotification.invocations[0].a).toContain("browsers quitting soon")

    // after 60 seconds pass, we quit the browsers
    await scheduler.advance(by: .seconds(1))
    await expect(quitBrowsers.invocations).toEqual(1)
  }

  func testReceivingSuspensionDuring60SecondCountdownCancelsTimer() async {
    let store = TestStore(initialState: AppReducer.State(filter: .init(
      // start with 30 second suspension
      currentSuspensionExpiration: Date(timeIntervalSince1970: 30)
    )), reducer: AppReducer())

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

    await expect(showNotification.invocations.count).toEqual(1)
    await expect(showNotification.invocations[0].a).toContain("browsers quitting soon")

    await scheduler.advance(by: .seconds(30))

    // 30 seconds from quitting browsers, dad sends another suspension!
    await store.send(.websocket(.receivedMessage(.suspendFilter(for: 120, parentComment: nil)))) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 120)
    }

    await scheduler.advance(by: .seconds(31))
    await expect(quitBrowsers.invocations).toEqual(0) // ...and browsers never quit!

    // now, receive a MANUAL suspension
    await store.send(
      .adminAuthenticated(.adminWindow(.webview(.suspendFilterClicked(durationInSeconds: 30))))
    ) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 30)
    }

    // pretend 30 seconds passed and the filter notifies of suspension ending
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    // user notified again that browsers will quit
    await expect(showNotification.invocations.count).toEqual(3)
    await expect(showNotification.invocations[1].a).toContain("disabling filter")
    await expect(showNotification.invocations[2].a).toContain("browsers quitting soon")
    await scheduler.advance(by: .seconds(30))

    // now, receive a SECOND MANUAL suspension, which stops timer
    await store.send(
      .adminAuthenticated(.adminWindow(.webview(.suspendFilterClicked(durationInSeconds: 30))))
    ) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 30)
    }

    await scheduler.advance(by: .seconds(31))
    await expect(quitBrowsers.invocations).toEqual(0) // browsers never quit
  }
}
