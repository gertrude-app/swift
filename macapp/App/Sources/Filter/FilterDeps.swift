import Foundation
import SyncArch

public struct FilterDeps {
  public var security: SecurityClient
  public var storage: StorageClient
  public var now: @Sendable () -> Date
  public var uuid: @Sendable () -> UUID

  public init(
    security: SecurityClient,
    storage: StorageClient,
    now: @Sendable @escaping () -> Date,
    uuid: @Sendable @escaping () -> UUID
  ) {
    self.security = security
    self.storage = storage
    self.now = now
    self.uuid = uuid
  }
}

extension FilterDeps: SyncDeps {
  public static let live = Self(
    security: .live,
    storage: .live,
    now: { Date() },
    uuid: { UUID() }
  )
}

#if DEBUG
  import XCTestDynamicOverlay
  extension FilterDeps: SyncTestDeps {
    public static let failing = Self(
      security: .failing,
      storage: .failing,
      now: {
        XCTFail("FilterDeps.now not implemented")
        return Date()
      },
      uuid: {
        XCTFail("FilterDeps.uuid not implemented")
        return UUID()
      }
    )
  }
#endif
