import Core
import Dependencies
import Foundation
import Shared
import XCore

struct StorageClient: Sendable {
  var savePersistentState: @Sendable (Persistent.State) async throws -> Void
  var loadPersistentState: @Sendable () throws -> Persistent.State?
  var deleteAllPersistentState: @Sendable () async -> Void
}

extension StorageClient: DependencyKey {
  static var liveValue: Self {
    @Dependency(\.userDefaults) var userDefaults
    return Self(
      savePersistentState: { state in
        let key = "persistent.state.v\(Persistent.State.version)"
        userDefaults.setString(try JSON.encode(state), key)
      },
      loadPersistentState: {
        let key = "persistent.state.v\(Persistent.State.version)"
        return try userDefaults.getString(key).flatMap { string in
          try JSON.decode(string, as: Persistent.State.self)
        }
      },
      deleteAllPersistentState: {
        userDefaults.remove("persistent.state.v\(Persistent.State.version)")
      }
    )
  }
}

extension StorageClient: TestDependencyKey {
  static let testValue = Self(
    savePersistentState: { _ in },
    loadPersistentState: { nil },
    deleteAllPersistentState: {}
  )
}

extension DependencyValues {
  var storage: StorageClient {
    get { self[StorageClient.self] }
    set { self[StorageClient.self] = newValue }
  }
}
