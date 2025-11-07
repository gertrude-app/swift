import Dependencies
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

final class TimeChangeTests: XCTestCase {
  @MainActor
  func testChangeEventButNoDriftDetectedFromNetworkTime() async throws {
    let (store, _) = AppReducer.testStore(mockDeps: false) {
      $0.timestamp = .init(
        network: .reference,
        system: .reference - 1, // <-- very close to network time
        boottime: .reference - 2000,
      )
    }
    store.deps.network.isConnected = { true }
    store.deps.api.trustedNetworkTimestamp = { (.reference + 100).timeIntervalSince1970 }
    store.deps.date = .constant(.reference + 101) // <-- still very close
    store.deps.api.logSecurityEvent = { _, _ in fatalError("no security event logged") }

    await store.send(.application(.systemClockOrTimeZoneChanged))
  }

  @MainActor
  func testChangeEventButNoDriftDetectedFromNetworkTime_andExpectedDelta() async throws {
    let (store, _) = AppReducer.testStore(mockDeps: false) {
      $0.timestamp = .init(
        network: .reference,
        system: .reference - ((60 * 60 * 3) - 1), // <-- 3 hrs off at last trusted check
        boottime: .reference - 2000,
      )
    }
    store.deps.network.isConnected = { true }
    store.deps.api.trustedNetworkTimestamp = { (.reference + 100).timeIntervalSince1970 }
    store.deps.date = .constant(.reference - ((60 * 60 * 3) + 3)) // <-- still roughly 3 hours
    store.deps.api.logSecurityEvent = { _, _ in fatalError("no security event logged") }

    await store.send(.application(.systemClockOrTimeZoneChanged))
  }

  @MainActor
  func testChangeEventButDriftDetectedFromNetworkTime() async throws {
    let (store, _) = AppReducer.testStore(mockDeps: false) {
      $0.timestamp = .init(
        network: .reference,
        system: .reference - 1, // <-- very close to network time
        boottime: .reference - 2000,
      )
    }
    store.deps.network.isConnected = { true }
    store.deps.api.trustedNetworkTimestamp = { (.reference + 100).timeIntervalSince1970 }
    store.deps.date = .constant(.reference - (60 * 60 * 5)) // <-- suddenly 5 hours off!
    let securityEvent = spy2(on: (LogSecurityEvent.Input.self, UUID?.self), returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn
    store.deps.storage.loadPersistentState = { .mock } // used by security event wrapper

    await store.send(.application(.systemClockOrTimeZoneChanged))

    await expect(securityEvent.calls)
      .toEqual([Both(.init(.systemClockOrTimeZoneChanged, nil), nil)])
  }

  @MainActor
  func testChangeEventButNoDriftDetectedFromLastTimestamp_NoNetwork_NoDiff() async throws {
    let (store, _) = AppReducer.testStore(mockDeps: false) {
      $0.timestamp = .init(
        network: .reference,
        system: .reference + 1, // <-- functionally the same as network time
        boottime: .reference - 2000,
      )
    }
    store.deps.network.isConnected = { false }
    store.deps
      .date = .constant(.reference + 2000) // <-- 2000 seconds have passed since our last timestamp
    store.deps.device.boottime = { .reference - 2000 } // <-- boottime hasn't changed
    store.deps.api.logSecurityEvent = { _, _ in fatalError("no security event logged") }

    await store.send(.application(.systemClockOrTimeZoneChanged))
  }

  @MainActor
  func testChangeEventButNoDriftDetectedFromLastTimestamp_NoNetwork_WithDiff() async throws {
    let (store, _) = AppReducer.testStore(mockDeps: false) {
      $0.timestamp = .init(
        network: .reference,
        system: .reference + 10800, // <-- 3 hours diff
        boottime: .reference - 2000,
      )
    }
    store.deps.network.isConnected = { false }
    store.deps.date = .constant(.reference + 10800 + 2000) // <-- 2000s passed since last timestamp
    store.deps.device.boottime = { .reference - 2000 } // <-- but no bootime change, so no drift
    store.deps.api.logSecurityEvent = { _, _ in fatalError("no security event logged") }

    await store.send(.application(.systemClockOrTimeZoneChanged))
  }

  @MainActor
  func testChangeEventDriftDetectedFromBoottime_NoNetwork() async throws {
    let (store, _) = AppReducer.testStore(mockDeps: false) {
      $0.timestamp = .init(
        network: .reference,
        system: .reference + 1, // <-- functionally the same as network time
        boottime: .reference - 5000,
      )
    }
    store.deps.network.isConnected = { false }
    let securityEvent = spy2(on: (LogSecurityEvent.Input.self, UUID?.self), returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn
    store.deps.storage.loadPersistentState = { .mock } // used by security event wrapper

    // needed because no network, api buffers
    store.deps.api.getUserToken = { .deadbeef }
    store.deps.userDefaults.getString = { _ in nil }
    let setString = LockIsolated<[String]>([])
    store.deps.userDefaults.setString = { @Sendable key, _ in
      setString.withValue { $0.append(key) }
    }

    store.deps.date = .constant(.reference + 2000) // <-- 2000s have passed since our last timestamp
    store.deps.device.boottime = { .reference - 3000 } // <-- boottime way different, very fishy!

    await store.send(.application(.systemClockOrTimeZoneChanged))

    // we buffered a security event for when the network comes back
    expect(setString.value).toEqual(["bufferedSecurityEvents"])
  }
}
