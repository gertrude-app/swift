import GertieIOS

#if canImport(NetworkExtension)
  import NetworkExtension
#else
  public struct NEProviderStopReason {} // CI
#endif

public class FilterProxy {
  var rules: [BlockRule] = BlockRule.defaults
  var loadRules: () -> [BlockRule]?

  public init(
    rules: [BlockRule] = BlockRule.defaults,
    loadRules: @escaping () -> [BlockRule]?
  ) {
    self.rules = rules
    self.loadRules = loadRules
    self.readRules()
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
    } else if self.rules.blocksFlow(hostname: hostname, url: url, bundleId: bundleId) {
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

  enum FlowType {
    case browser
    case socket
  }
}

// helpers

public extension String {
  static let gertrudeBundleIdLong = "WFN83LM943.com.netrivet.gertrude-ios.app"
  static let gertrudeBundleIdShort = "com.netrivet.gertrude-ios.app"
}

// conformances

extension FilterProxy.FlowVerdict: Equatable, Sendable {}
extension FilterProxy.FlowType: Equatable, Sendable {}

// "exports" for filter

public typealias BlockRule = GertieIOS.BlockRule
