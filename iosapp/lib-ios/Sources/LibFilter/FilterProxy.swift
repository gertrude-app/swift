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

public struct FilterProxy {
  #if DEBUG
    static let FREQ_VERY_FAST: UInt = 3
    static let FREQ_FAST: UInt = 5
    static let FREQ_NORMAL: UInt = 10
    static let FREQ_SLOW: UInt = 15
    static let FREQ_VERY_SLOW: UInt = 20
  #else
    static let FREQ_VERY_FAST: UInt = 3
    static let FREQ_FAST: UInt = 5
    static let FREQ_NORMAL: UInt = 250
    static let FREQ_SLOW: UInt = 500
    static let FREQ_VERY_SLOW: UInt = 1000
  #endif

  @Dependency(\.osLog) var logger
  @Dependency(\.date.now) var now
  @Dependency(\.calendar) var calendar

  // NB: The filter target is allowed to WRITE to UserDefaults,
  // but if it does, the operating system seems to *clone* the
  // underlying database, and it no longer is connected to the
  // group container. This is not documented directly, but I've
  // tested & verified it, and it fits with how the docs say that
  // the filter is heavily sandboxed and is not allowed to export
  // data, hence we use a storage client that can ONLY read
  @Dependency(\.sharedStorageReader) var storage

  var protectionMode: ProtectionMode = .emergencyLockdown
  var count: UInt = 0
  var requestUpdate: Bool = false

  public init(protectionMode: ProtectionMode) {
    self.protectionMode = protectionMode
    self.logger.setPrefix("FILTER PROXY")
  }

  mutating func getRules() -> ProtectionMode {
    if self.count % FilterProxy.FREQ_VERY_SLOW == 0 {
      self.loadAndSetRules()
    }
    switch self.protectionMode {
    case .normal:
      self.requestUpdate = self.requestUpdate || self.count % FilterProxy.FREQ_SLOW == 0
    case .connected:
      self.requestUpdate = self.requestUpdate || self.count % FilterProxy.FREQ_NORMAL == 0
    case .onboarding:
      self.requestUpdate = self.requestUpdate || self.count % FilterProxy.FREQ_FAST == 0
    case .emergencyLockdown:
      self.requestUpdate = self.requestUpdate || self.count % FilterProxy.FREQ_FAST == 0
      self.loadAndSetRules()
    }
    return self.protectionMode
  }

  mutating func loadAndSetRules() {
    guard let mode = self.storage.loadProtectionMode() else {
      self.logger.log("no rules found")
      return
    }
    self.protectionMode = mode
    switch mode {
    case .normal([]), .onboarding([]), .connected([], _):
      self.logger.log("unexpected empty rules")
    case .normal(let rules):
      self.logger.log("read \(rules.count) (normal) rules")
    case .connected(let rules, _):
      self.logger.log("read \(rules.count) (connected) rules")
    case .onboarding(let rules):
      self.logger.log("read \(rules.count) (onboarding) rules")
    case .emergencyLockdown:
      self.logger.log("unexpected stored emergencyLockdown mode")
    }
  }

  public mutating func decideFlow(
    hostname: String? = nil,
    url: String? = nil,
    bundleId: String? = nil,
    flowType: FlowType? = nil
  ) -> FlowVerdict {
    self.count &+= 1 // wrapping add
    if hostname == "read-rules.xpc.gertrude.app" {
      self.loadAndSetRules()
      return .drop
    }

    #if DEBUG
      self.logger.log("Decide flow, rules: \(self.protectionMode.shortDesc)")
    #endif

    guard let rules = self.protectionMode.rules else {
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
      return self.allowFlow()
    }
  }

  mutating func decideLockdownFlow(
    hostname: String? = nil,
    url: String? = nil,
    bundleId: String? = nil,
    flowType: FlowType? = nil
  ) -> FlowVerdict {
    let components = self.calendar.dateComponents([.hour, .minute], from: self.now)
    if components.hour == 19, components.minute! >= 0, components.minute! <= 5 {
      return self.allowFlow()
    }

    let allowedSuffixes = ["gertrude.app", "apple.com", "icloud.com", "icloud.net"]
    if bundleId?.contains("com.netrivet.gertrude-ios.app") == true {
      return self.allowFlow()
    } else if bundleId?.contains("com.apple.mDNSResponder") == true {
      return self.allowFlow()
    } else if bundleId?.contains("com.apple.Preferences") == true {
      return self.allowFlow()
    } else if hostname == nil, url == nil {
      return self.allowFlow()
    } else if let hostname {
      for suffix in allowedSuffixes {
        if hostname.hasSuffix(suffix) {
          return self.allowFlow()
        }
      }
      return .drop
    } else if let url {
      let withoutScheme = url.replacingOccurrences(of: "https://", with: "")
      let segments = withoutScheme.split(separator: "/")
      let derivedHostname = segments.first ?? ""
      for suffix in allowedSuffixes {
        if derivedHostname.hasSuffix(suffix) {
          return self.allowFlow()
        }
      }
      return .drop
    } else {
      return .drop
    }
  }

  public mutating func handleRulesChanged() {
    self.loadAndSetRules()
  }

  public mutating func startFilter() {
    self.loadAndSetRules()
  }

  public func stopFilter(reason: NEProviderStopReason) {}

  mutating func allowFlow() -> FlowVerdict {
    if self.requestUpdate {
      self.requestUpdate = false
      return .updateAndAllow
    } else {
      return .allow
    }
  }
}

public extension FilterProxy {
  enum FlowVerdict {
    case allow
    case drop
    case updateAndAllow

    public var description: String {
      switch self {
      case .allow: "ALLOW"
      case .drop: "DROP"
      case .updateAndAllow: "ALLOW(w/ UPDATE)"
      }
    }
  }
}

// helpers

private func isGertrude(_ bundleId: String?) -> Bool {
  guard let bundleId else { return false }
  return bundleId == .gertrudeBundleIdLong || bundleId == .gertrudeBundleIdShort
}

// conformances

extension FilterProxy.FlowVerdict: Equatable, Sendable {}

// "exports" for filter

public typealias BlockRule = GertieIOS.BlockRule
public typealias FlowType = GertieIOS.FlowType
