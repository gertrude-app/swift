import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

final class AdminFeatureTests: XCTestCase {
  @MainActor
  func testClickingInactiveAccountRecheckSendsAppCheckin() async throws {
    let (store, _) = AppReducer.testStore()
    let checkIn = spy(on: CheckIn_v2.Input.self, returning: CheckIn_v2.Output.mock)
    store.deps.api.checkIn = checkIn.fn

    await store.send(.adminWindow(.webview(.inactiveAccountRecheckClicked)))
    expect(await checkIn.calls).toHaveCount(1)

    await store.send(.blockedRequests(.webview(.inactiveAccountRecheckClicked)))
    expect(await checkIn.calls).toHaveCount(2)

    await store.send(.requestSuspension(.webview(.inactiveAccountRecheckClicked)))
    expect(await checkIn.calls).toHaveCount(3)
  }
}
