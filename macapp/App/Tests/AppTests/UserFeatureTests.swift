import ComposableArchitecture
import MacAppRoute
import PairQL
import TestSupport
import XCTest
import XExpect

@testable import App

final class UserFeatureTests: XCTestCase {
  func testUserDisconnectsAfterFiveApiCallsShowMissingToken() async {
    let (store, _) = AppReducer.testStore { $0.user = .init(data: .mock) }

    let error = PqlError(
      id: "123",
      requestId: "345",
      type: .notFound,
      debugMessage: "oops",
      appTag: .userTokenNotFound // <-- specific error, user token not found
    )

    for _ in 1 ... 7 {
      await store.send(.checkIn(result: .failure(error), reason: .heartbeat))
    }

    // seven failures not enough
    expect(store.state.user.numTimesUserTokenNotFound).toEqual(7)
    await store.send(.heartbeat(.everySixHours))
    expect(store.state.user).not.toBeNil()

    // checking heartbeat w/ > 8 failures triggers auto-disconnect
    await store.send(.checkIn(result: .failure(error), reason: .heartbeat))
    expect(store.state.user.numTimesUserTokenNotFound).toEqual(8)
    await store.send(.heartbeat(.everySixHours))

    await store.receive(.history(.userConnection(.disconnectMissingUser))) {
      $0.user = .init()
    }
  }

  func testSuccessfulApiRequestsRestartsCount() async {
    let (store, _) = AppReducer.testStore { $0.user = .init(data: .mock) }
    store.deps.updater = .mock

    let error = PqlError(
      id: "123",
      requestId: "345",
      type: .notFound,
      debugMessage: "oops",
      appTag: .userTokenNotFound // <-- specific error, user token not found
    )

    for _ in 1 ... 7 {
      await store.send(.checkIn(result: .failure(error), reason: .heartbeat))
    }

    // seven failures...
    expect(store.state.user.numTimesUserTokenNotFound).toEqual(7)
    await store.send(.heartbeat(.everySixHours))
    expect(store.state.user).not.toBeNil()

    // success restarts count
    await store.send(.checkIn(result: .success(.mock), reason: .heartbeat))

    await store.send(.checkIn(result: .failure(error), reason: .heartbeat))
    expect(store.state.user.numTimesUserTokenNotFound).toEqual(1)
    await store.send(.heartbeat(.everySixHours))

    expect(store.state.user).not.toBeNil() // still not disconnected
  }

  @MainActor
  func testNotifies5MinutestBeforeDowntime() async {
    // the time is: 2024-10-16 21:53, i.e. 9:53PM, 7 minutes before downtime
    let now = Calendar.current
      .date(from: DateComponents(year: 2024, month: 10, day: 16, hour: 21, minute: 53))!

    let (store, scheduler) = AppReducer.testStore(mockDeps: true) {
      $0.user.data = .mock {
        $0.downtime = .init(
          start: .init(hour: 22, minute: 0), // <-- downtime starts at 10PM
          end: .init(hour: 5, minute: 0)
        )
      }
    }

    store.deps.api.checkIn = { _ in throw TestErr("stop checkin") }
    store.deps.device.currentUserHasScreen = { true }
    store.deps.device.screensaverRunning = { false }
    store.deps.device.showNotification = { _, _ in fatalError() }
    store.deps.storage.loadPersistentState = { nil }
    let time = ControllingNow(starting: now, with: scheduler)
    store.deps.date = time.generator

    // start the heartbeat
    await store.send(.startProtecting(user: store.state.user.data!))

    await time.advance(seconds: 60)
    expect(store.state.user.data?.downtime?.start).toEqual(.init(hour: 22, minute: 0))
    await store.receive(.heartbeat(.everyMinute)) // 9:54 PM

    let notification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = notification.fn

    await time.advance(seconds: 60)
    await store.receive(.heartbeat(.everyMinute)) // <-- 9:55 PM, notify!

    await expect(notification.calls)
      .toEqual([.init("😴 Downtime starting in 5 minutes", "Save any important work now!")])

    store.deps.device.showNotification = { _, _ in fatalError() }
    for _ in 1 ... 6 {
      await time.advance(seconds: 60)
      await store.receive(.heartbeat(.everyMinute))
    }
  }
}
