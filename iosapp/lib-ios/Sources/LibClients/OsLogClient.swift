import Dependencies
import DependenciesMacros
import os.log

@DependencyClient
public struct OsLogClient: Sendable {
  public var log: @Sendable (String) -> Void
  public var debug: @Sendable (String) -> Void
  public var setPrefix: @Sendable (String) -> Void
}

extension OsLogClient: DependencyKey {
  public static var liveValue: OsLogClient {
    let prefix = LockIsolated<String?>(nil)
    return .init(
      log: { msg in
        if let prefix = prefix.value {
          os_log("[G•] %{public}s %{public}s", prefix, msg)
        } else {
          os_log("[G•] %{public}s", msg)
        }
      },
      debug: { msg in
        if let prefix = prefix.value {
          os_log("[D•] %{public}s %{public}s", prefix, msg)
        } else {
          os_log("[D•] %{public}s", msg)
        }
      },
      setPrefix: { newValue in
        prefix.setValue(newValue)
      }
    )
  }
}

extension OsLogClient: TestDependencyKey {
  public static let testValue = OsLogClient(
    log: unimplemented("OsLogClient.log"),
    debug: unimplemented("OsLogClient.debug"),
    setPrefix: { _ in } // <-- never want test failures from this
  )

  public static let noop = OsLogClient(
    log: { _ in },
    debug: { _ in },
    setPrefix: { _ in }
  )
}

public extension DependencyValues {
  var osLog: OsLogClient {
    get { self[OsLogClient.self] }
    set { self[OsLogClient.self] = newValue }
  }
}
