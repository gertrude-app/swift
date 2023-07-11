import Core
import Foundation
import Gertie
import SyncArch
import XCore

public struct StorageClient: Sendable {
  public var savePersistentState: @Sendable (Persistent.State) throws -> Void
  public var loadPersistentState: @Sendable () throws -> Persistent.State?
  public var loadPersistentStateSync: @Sendable () throws -> Persistent.State?
  public var deleteAllPersistentState: @Sendable () -> Void
  public var deleteAll: @Sendable () -> Void

  public init(
    savePersistentState: @Sendable @escaping (Persistent.State) throws -> Void,
    loadPersistentState: @Sendable @escaping () throws -> Persistent.State?,
    loadPersistentStateSync: @Sendable @escaping () throws -> Persistent.State?,
    deleteAllPersistentState: @Sendable @escaping () -> Void,
    deleteAll: @Sendable @escaping () -> Void
  ) {
    self.savePersistentState = savePersistentState
    self.loadPersistentState = loadPersistentState
    self.loadPersistentStateSync = loadPersistentStateSync
    self.deleteAllPersistentState = deleteAllPersistentState
    self.deleteAll = deleteAll
  }
}

extension StorageClient: SyncDeps {
  public static var live: Self {
    let userDefaults = UserDefaultsClient.live
    @Sendable func loadSync() throws -> Persistent.State? {
      try userDefaults.loadJson(
        at: Persistent.State.currentStorageKey,
        decoding: Persistent.State.self
      )
    }
    return Self(
      savePersistentState: { state in
        try userDefaults.saveJson(
          from: state,
          at: Persistent.State.currentStorageKey
        )
      },
      loadPersistentState: {
        if let current = try loadSync() { return current }
        return FilterMigrator(userDefaults: userDefaults).migrate()
      },
      loadPersistentStateSync: {
        try loadSync()
      },
      deleteAllPersistentState: {
        userDefaults.remove(Persistent.State.currentStorageKey)
      },
      deleteAll: {
        userDefaults.removeAll()
      }
    )
  }
}

#if DEBUG
  import XCTestDynamicOverlay

  extension StorageClient: SyncTestDeps {
    public static let failing = Self(
      savePersistentState: { _ in
        XCTFail("StorageClient.savePersistentState not implemented")
      },
      loadPersistentState: {
        XCTFail("StorageClient.loadPersistentState not implemented")
        return nil
      },
      loadPersistentStateSync: {
        XCTFail("StorageClient.loadPersistentStateSync not implemented")
        return nil
      },
      deleteAllPersistentState: {
        XCTFail("StorageClient.deleteAllPersistentState not implemented")
      },
      deleteAll: {
        XCTFail("StorageClient.deleteAll not implemented")
      }
    )
  }
#endif
