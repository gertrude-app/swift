import GertieIOS
import NetworkExtension

public class FilterManager {
  var loadRules: () -> Result<[BlockRule], FilterManagerError>
  var rules: [BlockRule] = BlockRule.defaults
  var errors: Set<FilterManagerError> = []

  public init(
    rules: [BlockRule] = BlockRule.defaults,
    loadRules: @escaping () -> Result<[BlockRule], FilterManagerError>
  ) {
    self.rules = rules
    self.loadRules = loadRules
  }

  public func decideFlow(
    hostname: String? = nil,
    url: String? = nil,
    bundleId: String? = nil,
    flowType: FlowType? = nil
  ) -> FlowVerdict {
    if bundleId == .gertrudeBundleIdLong || bundleId == .gertrudeBundleIdShort {
      if hostname == "read-rules.gertrude.app" {
        self.readRules()
        return .drop
      } else if url?.contains("/ios-filter-errors-v1/") == true {
        if url?.contains("/no-rules-found/") == true {
          return self.errors.remove(.noRulesFound) != nil ? .allow : .drop
        } else if url?.contains("/rules-decode-failed/") == true {
          return self.errors.remove(.rulesDecodeFailed) != nil ? .allow : .drop
        } else {
          return .allow
        }
      } else {
        return .allow
      }
    } else if self.rules.blocksFlow(hostname: hostname, url: url, bundleId: bundleId) {
      return .drop
    } else {
      return .allow
    }
  }

  public func receiveHeartbeat() {
    self.readRules()
  }

  func readRules() {
    switch self.loadRules() {
    case .success(let newRules):
      self.rules = newRules
    case .failure(let error):
      self.errors.insert(error)
    }
  }

  public func startFilter() {
    self.readRules()
  }

  public func stopFilter(reason: NEProviderStopReason) {}
}

public enum FilterManagerError: Error, Equatable, Hashable {
  case noRulesFound
  case rulesDecodeFailed
}

public extension FilterManager {
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

extension FilterManager.FlowVerdict: Equatable, Sendable {}
extension FilterManager.FlowType: Equatable, Sendable {}

// export for filter

public typealias BlockRule = GertieIOS.BlockRule
