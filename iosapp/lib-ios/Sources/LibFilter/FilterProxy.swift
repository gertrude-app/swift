import Dependencies
import GertieIOS
import LibClients
import LibCore

#if canImport(NetworkExtension)
  import NetworkExtension
#else
  public struct NEProviderStopReason {} // CI
#endif

public class FilterProxy {
  @Dependency(\.osLog) var logger
  @Dependency(\.storage) var storage
  @Dependency(\.suspendingClock) var clock

  var protectionMode: ProtectionMode
  var heartbeatTask: Task<Void, Error>?
  var normalHeartbeatInterval: Duration
  var hearbeatInterval: Duration = .seconds(10)

  public init(
    protectionMode: ProtectionMode,
    normalHeartbeatInterval: Duration = .minutes(5)
  ) {
    self.protectionMode = protectionMode
    self.normalHeartbeatInterval = normalHeartbeatInterval
    self.logger.setPrefix("FILTER PROXY")
    self.readRules()
    self.startHeartbeat()
  }

  func startHeartbeat() {
    self.heartbeatTask = Task {
      while true {
        try await self.clock.sleep(for: self.hearbeatInterval)
        self.receiveHeartbeat()
      }
    }
  }

  func loadRules() -> ProtectionMode? {
    guard let data = self.storage.loadData(forKey: .protectionModeStorageKey) else {
      self.logger.log("no rules found")
      return nil
    }
    do {
      let mode = try JSONDecoder().decode(ProtectionMode.self, from: data)
      switch mode {
      case .normal([]), .onboarding([]):
        self.logger.log("unexpected empty rules")
        return .emergencyLockdown
      case .normal(let rules):
        self.logger.log("read \(rules.count) (normal) rules")
      case .onboarding(let rules):
        self.logger.log("read \(rules.count) (onboarding) rules")
      case .emergencyLockdown:
        self.logger.log("unexpected stored emergencyLockdown mode")
      }
      return mode
    } catch {
      self.logger.log("error decoding rules: \(String(reflecting: error))")
      return nil
    }
  }

  public func decideFlow(
    hostname: String? = nil,
    url: String? = nil,
    bundleId: String? = nil,
    flowType: FlowType? = nil
  ) -> FlowVerdict {
    if hostname == "read-rules.gertrude.app" {
      self.readRules()
      return .drop
    }

    guard let rules = self.protectionMode.rules else {
      if bundleId?.contains("com.ftc.gertrude-ios.app") == true {
        return .allow
      } else if let hostname {
        return hostname.hasSuffix("gertrude.app") ? .allow : .drop
      } else if let url {
        let withoutScheme = url.replacingOccurrences(of: "https://", with: "")
        let segments = withoutScheme.split(separator: "/")
        let host = segments.first ?? ""
        return host == "api.gertrude.app" || host == "gertrude.app" ? .allow : .drop
      } else {
        return .drop
      }
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

  public func handleRulesChanged() {
    self.readRules()
  }

  public func receiveHeartbeat() {
    self.readRules()
  }

  func readRules() {
    // defensively set to check again quickly...
    self.hearbeatInterval = .seconds(10)
    guard let loadedMode = self.loadRules() else {
      return
    }
    self.protectionMode = loadedMode
    if loadedMode != .emergencyLockdown {
      // ...only setting normal if we get valid rules
      self.hearbeatInterval = self.normalHeartbeatInterval
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
      case .allow: return "ALLOW"
      case .drop: return "DROP"
      }
    }
  }
}

// helpers

public extension String {
  static let gertrudeBundleIdLong = "J83773RWC3.com.ftc.gertrude-ios.app"
  static let gertrudeBundleIdShort = "com.ftc.gertrude-ios.app"
}

// conformances

extension FilterProxy.FlowVerdict: Equatable, Sendable {}

// "exports" for filter

public typealias BlockRule = GertieIOS.BlockRule
public typealias FlowType = GertieIOS.FlowType
