import Dependencies
import Foundation
import XCore

struct StorageClient: Sendable {
  var savePersistentState: @Sendable (Persistent.State) async throws -> Void
  var loadPersistentState: @Sendable () async throws -> Persistent.State?
  var deleteAllPersistentState: @Sendable () async -> Void
}

extension StorageClient: DependencyKey {
  static var liveValue: Self {
    @Dependency(\.api) var api
    @Dependency(\.userDefaults) var userDefaults
    return Self(
      savePersistentState: { state in
        let key = "persistent.state.v\(Persistent.State.version)"
        userDefaults.setString(try JSON.encode(state), key)
      },
      loadPersistentState: {
        await AppMigrator(api: api, userDefaults: userDefaults)
          .migratePersistedState()
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
