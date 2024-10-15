import ComposableArchitecture
import XCTest

@testable import LibIOS

final class AppTests: XCTestCase {
  func testAppSendsFirstLaunchEventWhenNoLaunchDatePresent() async throws {
    let logDetails = LockIsolated<[String]>([])
    let storedDates = LockIsolated<[Date]>([])
    let store = await TestStore(initialState: AppReducer.State()) {
      AppReducer()
    } withDependencies: {
      $0.date = .constant(.reference)
      $0.api.logEvent = { @Sendable id, detail in
        logDetails.withValue { $0.append(detail ?? "") }
      }
      $0.storage.object = { @Sendable key in nil }
      $0.storage.set = { @Sendable value, key in
        storedDates.withValue { $0.append(value as! Date) }
      }
    }

    await store.send(.appLaunched)

    await store.receive(.setRunning(false)) {
      $0.appState = .welcome
    }
    await store.receive(.setFirstLaunch(.reference)) {
      $0.firstLaunch = .reference
    }

    XCTAssertEqual(storedDates.value, [.reference])
    XCTAssertEqual(logDetails.value, ["first launch"])
  }

  func testNoApiEventWhenFirstLaunchPresent() async throws {
    let store = await TestStore(initialState: AppReducer.State()) {
      AppReducer()
    } withDependencies: {
      $0.storage.object = { @Sendable _ in Date.epoch }
    }

    await store.send(.appLaunched)

    await store.receive(.setRunning(false)) {
      $0.appState = .welcome
    }
    await store.receive(.setFirstLaunch(.epoch)) {
      $0.firstLaunch = .epoch
    }
  }
}

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}
