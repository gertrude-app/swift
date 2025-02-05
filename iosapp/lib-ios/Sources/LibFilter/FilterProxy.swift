import Dependencies
import GertieIOS
import LibClients

#if canImport(NetworkExtension)
  import NetworkExtension
#else
  public struct NEProviderStopReason {} // CI
#endif

public class FilterProxy {
  @Dependency(\.osLog) var logger
  @Dependency(\.storage) var storage
  @Dependency(\.suspendingClock) var clock

  var rules: [BlockRule]
  var heartbeatTask: Task<Void, Error>?

  public init(rules: [BlockRule]) {
    self.rules = rules
    self.logger.setPrefix("FILTER PROXY")
    self.readRules()
  }

  public func startHeartbeat(interval: Duration) {
    self.heartbeatTask = Task {
      while true {
        try await self.clock.sleep(for: interval)
        self.receiveHeartbeat()
      }
    }
  }

  func loadRules() -> [BlockRule]? {
    guard let data = self.storage.loadData(forKey: .blockRulesStorageKey) else {
      self.logger.log("no rules found")
      return nil
    }
    do {
      let rules = try JSONDecoder().decode([BlockRule].self, from: data)
      self.logger.log("read \(rules.count) rules")
      return rules
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
    } else if self.rules.blocksFlow(
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
    if let newRules = self.loadRules() {
      self.rules = newRules
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
  static let gertrudeBundleIdLong = "WFN83LM943.com.netrivet.gertrude-ios.app"
  static let gertrudeBundleIdShort = "com.netrivet.gertrude-ios.app"
}

// conformances

extension FilterProxy.FlowVerdict: Equatable, Sendable {}

// "exports" for filter

public typealias BlockRule = GertieIOS.BlockRule
public typealias FlowType = GertieIOS.FlowType
