import ComposableArchitecture
import Gertie
import MacAppRoute
import TestSupport
import XCore
import XCTest
import XExpect

@testable import App

final class SecurityEventTests: XCTestCase {
  @MainActor
  func testResendsEventsBufferedWhenNoInternet() async throws {
    let (store, _) = AppReducer.testStore(mockDeps: true)
    store.deps.api.logSecurityEvent = { _, _ in fatalError("not called w/ no internet") }
    store.deps.api.getUserToken = { 1 }
    store.deps.network.isConnected = { false }
    store.deps.date.now = Date(timeIntervalSince1970: 0)
    store.deps.userDefaults.getString = { _ in nil }

    let setStringCalls = LockIsolated<[Both<String, String>]>([])
    store.deps.userDefaults.setString = { key, value in
      setStringCalls.withValue { $0.append(.init(key, value)) }
    }

    // we can't send this event because there's no internet connection
    await store.send(
      .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(durationInSeconds: 30))))
    )

    // the event gets buffered
    let event1 = BufferedSecurityEvent(
      deviceId: .deadbeef,
      userToken: 1,
      event: .filterSuspensionGrantedByAdmin,
      detail: "for < 1 min (at \(store.deps.date.now))"
    )

    let event1Json = try JSON.encode([event1])
    expect(setStringCalls.value).toEqual([.init(event1Json, .bufferedSecurityEventsKey)])

    // then another event comes in
    store.deps.userDefaults.getString = { _ in event1Json } // prev event is on disk
    await store.send(.adminAuthed(.adminWindow(.webview(.gotoScreenClicked(screen: .advanced)))))

    let event2 = BufferedSecurityEvent(
      deviceId: .deadbeef,
      userToken: 1,
      event: .advancedSettingsOpened,
      detail: "at \(store.deps.date.now)"
    )
    expect(setStringCalls.value).toEqual([
      .init(event1Json, .bufferedSecurityEventsKey),
      .init(try JSON.encode([event1, event2]), .bufferedSecurityEventsKey),
    ])

    // internet comes back on
    store.deps.network.isConnected = { true }
    let securityEvent = spy2(on: (LogSecurityEvent.Input.self, UUID?.self), returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn

    // so, heartbeat should resend buffered events
    store.deps.api.getUserToken = { 2 } // ensure we test that the STORED token is used
    let getStringCalled = LockIsolated(false)
    store.deps.userDefaults.getString = { _ in
      getStringCalled.withValue { $0 = true }
      return try! JSON.encode([event1, event2])
    }
    let removeFn = spySync(on: String.self, returning: ())
    store.deps.userDefaults.remove = removeFn.fn

    await store.send(.heartbeat(.everyFiveMinutes))

    await expect(securityEvent.calls).toEqual([
      Both(
        .init(
          deviceId: .deadbeef,
          event: "\(SecurityEvent.MacApp.filterSuspensionGrantedByAdmin)",
          detail: "for < 1 min (at \(store.deps.date.now))"
        ),
        1 // <-- the stored token
      ),
      Both(
        .init(
          deviceId: .deadbeef,
          event: "\(SecurityEvent.MacApp.advancedSettingsOpened)",
          detail: "at \(store.deps.date.now)"
        ),
        1 // <-- the stored token
      ),
    ])

    // buffered events should be cleared and not resent
    expect(removeFn.calls).toEqual([.bufferedSecurityEventsKey])
  }
}
