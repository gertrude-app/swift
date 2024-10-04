import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

final class ApplicationFeatureTests: XCTestCase {
  @MainActor
  func testSystemClockChangedEmitsSecurityEvent() async throws {
    let (store, _) = AppReducer.testStore()
    let securityEvent = spy2(on: (LogSecurityEvent.Input.self, UUID?.self), returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn

    await store.send(.application(.systemClockOrTimeZoneChanged))

    await expect(securityEvent.calls)
      .toEqual([Both(.init(.systemClockOrTimeZoneChanged, nil), nil)])
  }
}
