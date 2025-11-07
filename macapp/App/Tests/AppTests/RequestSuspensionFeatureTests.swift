import ClientInterfaces
import ComposableArchitecture
import Core
import MacAppRoute
import TaggedTime
import TestSupport
import XCore
import XCTest
import XExpect

@testable import App

final class RequestSuspensionFeatureTests: XCTestCase {
  @MainActor
  func testRequestSuspensionHappyPath() async throws {
    let (store, bgQueue) = AppReducer.testStore { $0.user.data = .mock }
    await store.send(.application(.didFinishLaunching)) // start heartbeat

    let reqId = UUID()
    await store.send(.requestSuspension(.createSuspensionRequest(.success(reqId)))) {
      $0.requestSuspension.pending = .init(id: reqId, createdAt: .epoch)
    }

    let checkIn = spy(on: CheckIn_v2.Input.self, returning: CheckIn_v2.Output.mock)
    store.deps.api.checkIn = checkIn.fn

    // because we have a pending suspension, the .everyMinute heartbeat will check
    await expect(checkIn.calls.count).toEqual(0)
    await bgQueue.advance(by: .seconds(60))
    await expect(checkIn.calls.count).toEqual(1)
    await expect(checkIn.calls[0].pendingFilterSuspension).toEqual(reqId)

    store.assert {
      // heartbeat check returned nada, so we're still waiting for parent response
      $0.requestSuspension.pending = .init(id: reqId, createdAt: .epoch)
    }

    // now the websocket gets the decision from the parent
    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: reqId,
      decision: .accepted(duration: 33, extraMonitoring: nil),
      comment: nil,
    )))) {
      // so we we nil out the pending request..
      $0.requestSuspension.pending = nil
    }

    // ...and don't check in the heartbeat again
    await bgQueue.advance(by: .seconds(60 * 10))
    await expect(checkIn.calls.count).toEqual(1)
  }

  @MainActor
  func testHearbeatFallbackCanStartAFilterSuspensionIfWebsocketNeverGetsMessage() async {
    let (store, bgQueue) = AppReducer.testStore { $0.user.data = .mock }
    await store.send(.application(.didFinishLaunching)) // start heartbeat

    let reqId = UUID()
    await store.send(.requestSuspension(.createSuspensionRequest(.success(reqId)))) {
      $0.requestSuspension.pending = .init(id: reqId, createdAt: .epoch)
    }

    let checkIn: Spy<CheckIn_v2.Output, CheckIn_v2.Input> = spy(returning: [
      CheckIn_v2.Output.mock,
      CheckIn_v2.Output.mock,
      CheckIn_v2.Output.empty {
        $0.resolvedFilterSuspension = .init(
          id: reqId,
          decision: .accepted(duration: 33, extraMonitoring: .setScreenshotFreq(10)),
          comment: "ok",
        )
      },
    ])

    store.deps.api.checkIn = checkIn.fn
    let suspendFilter = spy(on: Seconds<Int>.self, returning: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.suspendFilter = suspendFilter.fn
    store.deps.date.now = .epoch

    await store.send(.requestSuspension(.createSuspensionRequest(.success(reqId)))) {
      $0.requestSuspension.pending = .init(id: reqId, createdAt: .epoch)
    }

    // first two .everyMinute heartbeats come up empty...
    await expect(checkIn.calls.count).toEqual(0)
    await bgQueue.advance(by: .seconds(60))
    await expect(checkIn.calls.count).toEqual(1)
    await bgQueue.advance(by: .seconds(60))
    await expect(checkIn.calls.count).toEqual(2)
    store.assert {
      // ... so we're still pending
      $0.requestSuspension.pending = .init(id: reqId, createdAt: .epoch)
    }

    let notification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = notification.fn

    await bgQueue.advance(by: .seconds(60))
    await expect(checkIn.calls.count).toEqual(3)

    await store.receive(.checkIn(result: .success(.init(
      adminAccountStatus: .active,
      appManifest: .empty,
      keychains: [],
      latestRelease: .init(semver: "2.0.4"),
      updateReleaseChannel: .stable,
      userData: .empty,
      browsers: [],
      resolvedFilterSuspension: .init(
        id: reqId,
        decision: .accepted(duration: 33, extraMonitoring: .setScreenshotFreq(10)),
        comment: "ok",
      ),
      trustedTime: 0,
    )), reason: .pendingRequest)) {
      $0.requestSuspension.pending = nil
      $0.monitoring.suspensionMonitoring!.screenshotFrequency = 10
    }

    // the filter was suspended
    await expect(suspendFilter.calls).toEqual([33])
    // with a notification
    await expect(notification.calls.count).toEqual(1)
    await expect(notification.calls[0].a).toEqual("👀 Temporarily disabling filter")

    // we should not poll again
    await bgQueue.advance(by: .seconds(60 * 5))
    await expect(checkIn.calls.count).toEqual(3)
  }

  @MainActor
  func testHeartbeatPollFallbackEventuallyGivesUp() async {
    let (store, bgQueue) = AppReducer.testStore { $0.user.data = .mock }
    let time = ControllingNow(starting: .epoch, with: bgQueue)
    store.deps.date = time.generator
    await store.send(.application(.didFinishLaunching)) // start heartbeat

    let reqId = UUID()
    await store.send(.requestSuspension(.createSuspensionRequest(.success(reqId)))) {
      $0.requestSuspension.pending = .init(id: reqId, createdAt: .epoch)
    }

    let checkIn = spy(on: CheckIn_v2.Input.self, returning: CheckIn_v2.Output.mock)
    store.deps.api.checkIn = checkIn.fn

    for i in 1 ... 10 {
      await time.advance(seconds: 60)
      await expect(checkIn.calls.count).toEqual(i)
    }

    store.assert {
      $0.requestSuspension.pending = .init(id: reqId, createdAt: .epoch)
    }

    await time.advance(seconds: 60)
    await expect(checkIn.calls.count).toEqual(10)
    await store.skipReceivedActions()
    store.assert {
      $0.requestSuspension.pending = nil
    }

    await time.advance(seconds: 60 * 4)
    await expect(checkIn.calls.count).toEqual(10) // still 10
  }

  @MainActor
  func testRequestingFilterSuspensionOrUnlockChecksAndRepairsWebsocketConnection() async {
    let (store, _) = AppReducer.testStore {
      $0.user.data = .mock
    }
    store.deps.websocket.state = { .notConnected }
    let connect = spy(on: UUID.self, returning: WebSocketClient.State.connected)
    store.deps.websocket.connect = connect.fn

    await store.send(
      .requestSuspension(
        .webview(.requestSubmitted(durationInSeconds: 30, comment: nil)),
      ),
    )

    await expect(connect.calls.count).toEqual(1)

    await store
      .send(.blockedRequests(.webview(.unlockRequestSubmitted(comment: nil))))

    await expect(connect.calls.count).toEqual(2)
  }

  @MainActor
  func testFilterCommunicationConfirmationSucceeded() async {
    let (store, _) = AppReducer.testStore {
      $0.requestSuspension.filterCommunicationConfirmed = false // <-- prove nilling out
    }

    // can't connect, or repair connection
    store.deps.filterXpc.checkConnectionHealth = { .success(()) }

    await store.send(.menuBar(.suspendFilterClicked)) {
      $0.requestSuspension.filterCommunicationConfirmed = nil // <-- nils out for fresh confirmation
      $0.requestSuspension.windowOpen = true
    }

    await store.receive(.requestSuspension(.receivedFilterCommunicationConfirmation(true))) {
      $0.requestSuspension.filterCommunicationConfirmed = true
    }
  }

  @MainActor
  func testFilterCommunicationConfirmationFailed() async {
    let (store, _) = AppReducer.testStore {
      $0.requestSuspension.filterCommunicationConfirmed = true
    }

    // can't connect, or repair connection
    store.deps.filterXpc.checkConnectionHealth = { .failure(.unknownError("???")) }
    store.deps.filterXpc.establishConnection = { .failure(.unknownError("???")) }

    await store.send(.menuBar(.suspendFilterClicked)) {
      $0.requestSuspension.filterCommunicationConfirmed = nil // <-- nils out for fresh confirmation
      $0.requestSuspension.windowOpen = true
    }

    await store.receive(.requestSuspension(.receivedFilterCommunicationConfirmation(false))) {
      $0.requestSuspension.filterCommunicationConfirmed = false
    }
  }

  @MainActor
  func testClickingAdministrateFromFilterCommFailureOpensAdmin() async {
    let (store, _) = AppReducer.testStore {
      $0.adminWindow.windowOpen = false
      $0.requestSuspension.windowOpen = true
    }

    await store
      .send(.adminAuthed(.requestSuspension(.webview(.noFilterCommunicationAdministrateClicked)))) {
        $0.adminWindow.windowOpen = true
        $0.adminWindow.screen = .healthCheck
        $0.requestSuspension.windowOpen = false
      }
  }
}
