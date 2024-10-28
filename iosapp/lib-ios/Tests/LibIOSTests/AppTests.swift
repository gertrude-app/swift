import ComposableArchitecture
import GertieIOS
import XCTest
import XExpect

@testable import LibIOS

final class AppTests: XCTestCase {
  @MainActor
  func testFirstLaunch() async throws {
    let logDetails = LockIsolated<[String]>([])
    let storedDates = LockIsolated<[Date]>([])
    let storedRules = LockIsolated<[[BlockRule]]>([])
    let store = TestStore(initialState: AppReducer.State()) {
      AppReducer()
    } withDependencies: {
      $0.date = .constant(.reference)
      $0.locale = Locale(identifier: "en_US")
      $0.api.logEvent = { @Sendable id, detail in
        logDetails.withValue { $0.append(detail ?? "") }
      }
      $0.api.fetchBlockRules = { [.bundleIdContains("bad")] }
      $0.storage.loadDate = { @Sendable key in nil }
      $0.storage.saveDate = { @Sendable value, key in
        storedDates.withValue { $0.append(value) }
      }
      $0.storage.saveCodable = { @Sendable value, key in
        storedRules.withValue { $0.append(value as! [BlockRule]) }
      }
    }

    await store.send(.appLaunched)

    await store.receive(.setFirstLaunch(.reference)) {
      $0.firstLaunch = .reference
    }
    await store.receive(.setRunning(false)) {
      $0.appState = .welcome
    }

    expect(storedDates.value).toEqual([.reference])
    expect(logDetails.value).toEqual(["first launch, region: `US`"])
    expect(storedRules.value).toEqual([[.bundleIdContains("bad")]])
  }

  @MainActor
  func testNoApiLogEventWhenFirstLaunchPresent() async throws {
    let store = TestStore(initialState: AppReducer.State()) {
      AppReducer()
    } withDependencies: {
      $0.storage.loadDate = { @Sendable _ in Date.epoch }
      $0.storage.saveCodable = { @Sendable _, _ in }
      $0.api.fetchBlockRules = { [] }
    }

    await store.send(.appLaunched)

    await store.receive(.setFirstLaunch(.epoch)) {
      $0.firstLaunch = .epoch
    }
    await store.receive(.setRunning(false)) {
      $0.appState = .welcome
    }
  }

  @MainActor
  func testRunningShake() async throws {
    let storedRules = LockIsolated<[[BlockRule]]>([])
    let fetchCalled = LockIsolated(0)
    let store = TestStore(initialState: AppReducer.State(appState: .running(showVendorId: false))) {
      AppReducer()
    } withDependencies: {
      $0.api.fetchBlockRules = {
        fetchCalled.withValue { $0 += 1 }
        return [.bundleIdContains("bad")]
      }
      $0.storage.saveCodable = { @Sendable value, key in
        storedRules.withValue { $0.append(value as! [BlockRule]) }
      }
    }

    await store.send(.runningShaked) {
      $0.appState = .running(showVendorId: true)
    }

    expect(fetchCalled.value).toEqual(1)
    expect(storedRules.value).toEqual([[.bundleIdContains("bad")]])
  }
}

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}
