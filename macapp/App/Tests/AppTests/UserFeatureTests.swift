import ComposableArchitecture
import PairQL
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

    await store.send(.user(.refreshRules(result: .failure(error), userInitiated: false)))
    await store.send(.user(.refreshRules(result: .failure(error), userInitiated: false)))
    await store.send(.user(.refreshRules(result: .failure(error), userInitiated: false)))
    await store.send(.user(.refreshRules(result: .failure(error), userInitiated: false)))

    expect(store.state.user).not.toBeNil()

    // fifth failure triggers auto-disconnect
    await store.send(.user(.refreshRules(result: .failure(error), userInitiated: false)))

    await store.receive(.history(.userConnection(.disconnectMissingUser))) {
      $0.user = nil
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

    await store.send(.user(.refreshRules(result: .failure(error), userInitiated: false)))
    await store.send(.user(.refreshRules(result: .failure(error), userInitiated: false)))
    await store.send(.user(.refreshRules(result: .failure(error), userInitiated: false)))
    await store.send(.user(.refreshRules(result: .failure(error), userInitiated: false)))

    expect(store.state.user).not.toBeNil()

    // success restarts count
    await store.send(.user(.refreshRules(result: .success(.mock), userInitiated: false)))

    await store.send(.user(.refreshRules(result: .failure(error), userInitiated: false)))
    await store.send(.user(.refreshRules(result: .failure(error), userInitiated: false)))
    await store.send(.user(.refreshRules(result: .failure(error), userInitiated: false)))

    expect(store.state.user).not.toBeNil()
  }
}
