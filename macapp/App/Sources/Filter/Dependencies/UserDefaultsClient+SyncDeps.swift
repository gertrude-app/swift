import Core
import SyncArch

extension UserDefaultsClient: SyncDeps {
  public static let live = Self.liveValue
}

#if DEBUG
  import XCTestDynamicOverlay
  extension UserDefaultsClient: SyncTestDeps {
    public static let failing = Self(
      setString: { _, _ in
        XCTFail("UserDefaultsClient.setString not implemented")
      },
      getString: { _ in
        XCTFail("UserDefaultsClient.getString not implemented")
        return nil
      },
      remove: { _ in
        XCTFail("UserDefaultsClient.remove not implemented")
      },
      removeAll: {
        XCTFail("UserDefaultsClient.removeAll not implemented")
      }
    )
  }
#endif
