import ComposableArchitecture
import MacAppRoute
import PairQL
import TestSupport
import XCTest
import XExpect

@testable import App

@MainActor final class UserFeatureTests: XCTestCase {
  func testUserDisconnectsAfterFiveApiCallsShowMissingToken() async {
    let (store, _) = AppReducer.testStore {
      $0.user = .init(data: .mock)
    }

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
    let (store, _) = AppReducer.testStore {
      $0.user = .init(data: .mock)
    }

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
}
