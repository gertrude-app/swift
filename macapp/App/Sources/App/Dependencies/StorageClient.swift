import Dependencies
import Foundation
import XCore

struct StorageClient: Sendable {
  var savePersistentState: @Sendable (Persistent.State) async throws -> Void
  var loadPersistentState: @Sendable () async throws -> Persistent.State?
  var deleteAllPersistentState: @Sendable () async -> Void
  var deleteAll: @Sendable () async -> Void
}

extension StorageClient: DependencyKey {
  static var liveValue: Self {
    @Dependency(\.api) var api
    @Dependency(\.userDefaults) var userDefaults
    return Self(
      savePersistentState: { state in
        try userDefaults.saveJson(
          from: state,
          at: Persistent.State.storageKey,
        )
      },
      loadPersistentState: {
        if let current = try? userDefaults.loadJson(
          at: Persistent.State.storageKey,
          decoding: Persistent.State.self,
        ) {
          return current
        }
        let migrator = AppMigrator(api: api, userDefaults: userDefaults)
        return await migrator.migrate()
      },
      deleteAllPersistentState: {
        userDefaults.remove(Persistent.State.storageKey)
      },
      deleteAll: {
        userDefaults.removeAll()
      },
    )
  }
}

extension StorageClient: TestDependencyKey {
  static let testValue = Self(
    savePersistentState: unimplemented("StorageClient.savePersistentState"),
    loadPersistentState: unimplemented("StorageClient.loadPersistentState"),
    deleteAllPersistentState: unimplemented("StorageClient.deleteAllPersistentState"),
    deleteAll: unimplemented("StorageClient.deleteAll"),
  )
  static let mock = Self(
    savePersistentState: { _ in },
    loadPersistentState: { nil },
    deleteAllPersistentState: {},
    deleteAll: {},
  )
}

extension DependencyValues {
  var storage: StorageClient {
    get { self[StorageClient.self] }
    set { self[StorageClient.self] = newValue }
  }
}
