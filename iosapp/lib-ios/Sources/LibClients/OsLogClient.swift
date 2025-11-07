import Dependencies
import DependenciesMacros
import LibCore
import os.log

public typealias LogObserver = @Sendable (_ log: String, _ debug: Bool) -> Void

@DependencyClient
public struct OsLogClient: Sendable {
  public var log: @Sendable (String) -> Void
  public var debug: @Sendable (String) -> Void
  public var setPrefix: @Sendable (String) -> Void
  public var setObserver: @Sendable (@escaping LogObserver) -> Void
}

extension OsLogClient: DependencyKey {
  struct Helpers: Sendable {
    let prefix: String?
    let observer: LogObserver?
  }

  public static var liveValue: OsLogClient {
    let helpers = LockIsolated(Helpers(prefix: nil, observer: nil))
    return .init(
      log: { msg in
        let shared = helpers.value
        if let prefix = shared.prefix {
          os_log("[G•] %{public}s %{public}s", prefix, msg)
        } else {
          os_log("[G•] %{public}s", msg)
        }
        if let observer = shared.observer {
          observer(msg, false)
        }
      },
      debug: { msg in
        let shared = helpers.value
        if let prefix = shared.prefix {
          os_log("[D•] %{public}s %{public}s", prefix, msg)
        } else {
          os_log("[D•] %{public}s", msg)
        }
        if let observer = shared.observer {
          observer(msg, true)
        }
      },
      setPrefix: { newValue in
        helpers.setValue(Helpers(
          prefix: newValue,
          observer: helpers.value.observer,
        ))
      },
      setObserver: { newObserver in
        helpers.setValue(Helpers(
          prefix: helpers.value.prefix,
          observer: newObserver,
        ))
      },
    )
  }
}

public extension OsLogClient {
  func logReadProtectionMode(_ protectionMode: ProtectionMode?) {
    switch protectionMode {
    case nil:
      self.log("no rules found")
    case .normal(let rules):
      self.log("read \(rules.count) (normal) rules")
    case .onboarding(let rules):
      self.log("read \(rules.count) (onboarding) rules")
    case .connected(let rules, _):
      self.log("read \(rules.count) (connected) rules")
    case .emergencyLockdown:
      self.log("read emergency lockdown mode")
    }
  }
}

extension OsLogClient: TestDependencyKey {
  public static let testValue = OsLogClient(
    log: unimplemented("OsLogClient.log"),
    debug: unimplemented("OsLogClient.debug"),
    setPrefix: { _ in }, // <-- never want test failures from this
    setObserver: { _ in },
  )

  public static let noop = OsLogClient(
    log: { _ in },
    debug: { _ in },
    setPrefix: { _ in },
    setObserver: { _ in },
  )
}

public extension DependencyValues {
  var osLog: OsLogClient {
    get { self[OsLogClient.self] }
    set { self[OsLogClient.self] = newValue }
  }
}
