import Dependencies
import Models
import XCore
import XCTest
import XExpect

@testable import App

final class StorageClientTests: XCTestCase {
  func testLoadPersistentState() async throws {
    let observedKey = LockIsolated<String?>(nil)
    let state = Persistent.State(user: .mock)
    let client = withDependencies {
      $0.userDefaults.setString = { _, _ in XCTFail("Should not be called") }
      $0.userDefaults.getString = { key in
        observedKey.setValue(key)
        return try! JSON.encode(state)
      }
    } operation: {
      StorageClient.liveValue
    }

    let loaded = try await client.loadPersistentState()
    expect(loaded).toEqual(state)
    expect(observedKey.value).toEqual("persistent.state.v1")
  }

  func testSavePersistentState() async throws {
    let observed = LockIsolated<(key: String?, json: String?)>((nil, nil))
    let client = withDependencies {
      $0.userDefaults.setString = { observed.setValue(($1, $0)) }
      $0.userDefaults.getString = { _ in
        XCTFail("Should not be called")
        return nil
      }
    } operation: {
      StorageClient.liveValue
    }

    let state = Persistent.State(user: .mock)
    try await client.savePersistentState(state)
    expect(observed.value.key).toEqual("persistent.state.v1")
    expect(observed.value.json).toEqual(try! JSON.encode(state))
  }
}
