import Dependencies
import GertieIOS
import LibClients
import LibCore
import XCore

#if canImport(NetworkExtension)
  import NetworkExtension
#else
  public struct NEProviderStopReason {} // CI
#endif

public final class FilterProxy: Sendable {
  struct Deps: Sendable {
    @Dependency(\.osLog) var logger
    @Dependency(\.storage) var storage
    @Dependency(\.suspendingClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
  }

  struct HeartbeatDurations: Sendable {
    var normal: Duration
    var current: Duration
  }

  let deps = Deps()
  let protectionMode: Mutex<ProtectionMode>
  let heartbeatDurations: Mutex<HeartbeatDurations>
  let heartbeatTask: Mutex<Task<Void, Error>?>

  public init(
    protectionMode: ProtectionMode,
    normalHeartbeatInterval: Duration = .minutes(5)
  ) {
    self.heartbeatTask = Mutex(nil)
    self.protectionMode = Mutex(protectionMode)
    self.heartbeatDurations = Mutex(.init(normal: normalHeartbeatInterval, current: .seconds(10)))
    self.deps.logger.setPrefix("FILTER PROXY")
    self.readRules()
    self.startHeartbeat()
  }

  func startHeartbeat() {
    let task = Task {
      while true {
        let nextInterval = self.heartbeatDurations.withLock { $0.current }
        try await self.deps.clock.sleep(for: nextInterval)
        self.receiveHeartbeat()
      }
    }
    self.heartbeatTask.withLock { $0 = task }
  }

  func loadRules() -> ProtectionMode? {
    guard let data = self.deps.storage.loadData(forKey: .protectionModeStorageKey) else {
      self.deps.logger.log("no rules found")
      return nil
    }
    do {
      let mode = try JSONDecoder().decode(ProtectionMode.self, from: data)
      switch mode {
      case .normal([]), .onboarding([]):
        self.deps.logger.log("unexpected empty rules")
        return .emergencyLockdown
      case .normal(let rules):
        self.deps.logger.log("read \(rules.count) (normal) rules")
      case .onboarding(let rules):
        self.deps.logger.log("read \(rules.count) (onboarding) rules")
      case .emergencyLockdown:
        self.deps.logger.log("unexpected stored emergencyLockdown mode")
      case .suspended(until: let expiration, restoring: _):
        self.deps.logger.log("read filter suspended, resuming: \(expiration)")
      }
      return mode
    } catch {
      self.deps.logger.log("error decoding rules: \(String(reflecting: error))")
      return nil
    }
  }

  public func decideFlow(
    hostname: String? = nil,
    url: String? = nil,
    bundleId: String? = nil,
    flowType: FlowType? = nil
  ) -> FlowVerdict {
    if hostname == "read-rules.xpc.gertrude.app" {
      self.readRules()
      return .drop
    }

    #if DEBUG
      let desc = self.protectionMode.withLock { $0.shortDesc }
      self.deps.logger.log("Decide flow, rules: \(desc)")
    #endif

    if hostname == "suspend-filter.xpc.gertrude.app",
       let expiration = self.deps.storage.loadDate(forKey: .filterSuspensionExpirationKey),
       expiration > self.deps.now,
       isGertrude(bundleId) {
      self.deps.logger.log("suspending filter until \(expiration)")
      self.protectionMode.withLock { protectionMode in
        if !protectionMode.isSuspended {
          protectionMode = .suspended(until: expiration, restoring: protectionMode)
        }
      }
      return .drop
    }

    if hostname == "resume-filter.xpc.gertrude.app", isGertrude(bundleId),
       case .suspended(until: _, restoring: let previous) = self.protectionMode.withLock({ $0 }) {
      self.deps.logger.log("resuming filter")
      self.deps.storage.removeObject(forKey: .filterSuspensionExpirationKey)
      self.protectionMode.withLock { $0 = previous }
      return self.decideFlow(hostname: hostname, url: url, bundleId: bundleId, flowType: flowType)
    }

    // NB: this _should_ be extremely fast, because
    //  1) network requests originate relatively rarely
    //  2) it's likely that the filter only ever operates on a single thread
    //  3) underlying NSLock should not incur a syscall in low contention
    let protectionMode = self.protectionMode.withLock { $0 }

    guard let rules = protectionMode.rules else {
      if case .suspended(until: let expiration, restoring: let previous) = protectionMode {
        if expiration < self.deps.now {
          self.deps.storage.removeObject(forKey: .filterSuspensionExpirationKey)
          self.protectionMode.withLock { $0 = previous }
          return self.decideFlow(
            hostname: hostname,
            url: url,
            bundleId: bundleId,
            flowType: flowType
          )
        }
        return .allow
      }

      return self.decideLockdownFlow(
        hostname: hostname,
        url: url,
        bundleId: bundleId,
        flowType: flowType
      )
    }

    if rules.blocksFlow(
      hostname: hostname,
      url: url,
      bundleId: bundleId,
      flowType: flowType
    ) {
      return .drop
    } else {
      return .allow
    }
  }

  func decideLockdownFlow(
    hostname: String? = nil,
    url: String? = nil,
    bundleId: String? = nil,
    flowType: FlowType? = nil
  ) -> FlowVerdict {
    let components = self.deps.calendar.dateComponents([.hour, .minute], from: self.deps.now)
    if components.hour == 19, components.minute! >= 0, components.minute! <= 5 {
      return .allow
    }

    let allowedSuffixes = ["gertrude.app", "apple.com", "icloud.com", "icloud.net"]
    if bundleId?.contains("com.netrivet.gertrude-ios.app") == true {
      return .allow
    } else if bundleId?.contains("com.apple.mDNSResponder") == true {
      return .allow
    } else if bundleId?.contains("com.apple.Preferences") == true {
      return .allow
    } else if hostname == nil, url == nil {
      return .allow
    } else if let hostname {
      for suffix in allowedSuffixes {
        if hostname.hasSuffix(suffix) {
          return .allow
        }
      }
      return .drop
    } else if let url {
      let withoutScheme = url.replacingOccurrences(of: "https://", with: "")
      let segments = withoutScheme.split(separator: "/")
      let derivedHostname = segments.first ?? ""
      for suffix in allowedSuffixes {
        if derivedHostname.hasSuffix(suffix) {
          return .allow
        }
      }
      return .drop
    } else {
      return .drop
    }
  }

  public func handleRulesChanged() {
    self.readRules()
  }

  public func receiveHeartbeat() {
    self.readRules()
  }

  func readRules() {
    self.deps.logger.log("read rules")
    // defensively set to check again quickly...
    self.heartbeatDurations.withLock { $0.current = .seconds(10) }
    guard let loadedMode = self.loadRules() else {
      return
    }
    self.protectionMode.withLock { currentMode in
      if case .suspended(let expiration, _) = currentMode {
        currentMode = .suspended(until: expiration, restoring: loadedMode)
      } else {
        currentMode = loadedMode
      }
    }
    if loadedMode != .emergencyLockdown {
      // ...only setting normal if we get valid rules
      self.heartbeatDurations.withLock { $0.current = $0.normal }
    }
  }

  public func startFilter() {
    self.readRules()
  }

  public func stopFilter(reason: NEProviderStopReason) {}
}

public extension FilterProxy {
  enum FlowVerdict {
    case allow
    case drop

    public var description: String {
      switch self {
      case .allow: "ALLOW"
      case .drop: "DROP"
      }
    }
  }
}

// helpers

private func isGertrude(_ bundleId: String?) -> Bool {
  guard let bundleId else { return false }
  return bundleId == .gertrudeBundleIdLong || bundleId == .gertrudeBundleIdShort
}

public extension String {
  static let gertrudeBundleIdLong = "WFN83LM943.com.netrivet.gertrude-ios.app"
  static let gertrudeBundleIdShort = "com.netrivet.gertrude-ios.app"
}

// conformances

extension FilterProxy.FlowVerdict: Equatable, Sendable {}

// "exports" for filter

public typealias BlockRule = GertieIOS.BlockRule
public typealias FlowType = GertieIOS.FlowType
