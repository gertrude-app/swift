import Dependencies
import GertieIOS
import LibClients
import LibCore
import os.log
import XCore

#if canImport(NetworkExtension)
  import NetworkExtension
#else
  public struct NEProviderStopReason {} // CI
#endif

public struct FilterProxy {
  #if DEBUG
    static let FREQ_FAST: UInt = 10
    static let FREQ_NORMAL: UInt = 25
    static let FREQ_SLOW: UInt = 50
    static let FREQ_VERY_SLOW: UInt = 100
  #else
    static let FREQ_FAST: UInt = 25
    static let FREQ_NORMAL: UInt = 500
    static let FREQ_SLOW: UInt = 1000
    static let FREQ_VERY_SLOW: UInt = 3000
  #endif

  @Dependency(\.osLog) var logger
  @Dependency(\.date.now) public var now
  @Dependency(\.calendar) public var calendar

  // NB: The filter target is allowed to WRITE to UserDefaults,
  // but if it does, the operating system seems to *clone* the
  // underlying database, and it no longer is connected to the
  // group container. This is not documented directly, but I've
  // tested & verified it, and it fits with how the docs say that
  // the filter is heavily sandboxed and is not allowed to export
  // data, hence we use a storage client that can ONLY read
  @Dependency(\.sharedStorageReader) var storage

  var count: UInt = 0
  let memoryLogs: LockIsolated<[String]> = LockIsolated([])

  public private(set) var protectionMode: ProtectionMode = .emergencyLockdown

  public init(protectionMode: ProtectionMode) {
    self.protectionMode = protectionMode
    #if DEBUG
      self.logger.setObserver { [logs = self.memoryLogs] msg, isDebug in
        if !isDebug {
          logs.withValue { $0.append("\(Date()) [G•] FILTER PROXY \(msg.prefix(100))") }
        }
      }
    #endif
    self.logger.setPrefix("FILTER PROXY")
    self.logger.log("Initialized filter proxy")
  }

  mutating func shouldRequestUpdate() -> Bool {
    if self.count % FilterProxy.FREQ_VERY_SLOW == 0 {
      self.logger.log("re-read rules fallback, count: \(self.count)")
      self.loadAndSetRules()
    }
    switch self.protectionMode {
    case .normal:
      return self.count % FilterProxy.FREQ_SLOW == 0
    case .connected:
      return self.count % FilterProxy.FREQ_NORMAL == 0
    case .onboarding:
      return self.count % FilterProxy.FREQ_FAST == 0
    case .emergencyLockdown:
      self.loadAndSetRules()
      return self.count % FilterProxy.FREQ_FAST == 0
    }
  }

  mutating func loadAndSetRules() {
    let mode = self.storage.loadProtectionMode()
    self.logger.logReadProtectionMode(mode)
    mode.map { self.protectionMode = $0 }
  }

  // NB: from logging, it appears that this can get called from different threads
  // although big bursts of near simultaneous network connections seem to to be
  // handled by the same thread, instead of being interleaved, seems more like the
  // system puts the process to sleep after inactivity, then it wakes up on a new thread
  // so it's probably the correct mental model to consider this a single-threaded
  public mutating func decideFlow(_ systemFlow: NEFilterFlow) -> FlowVerdict {
    self.count &+= 1 // wrapping add

    let flow = self.toFilterFlow(systemFlow)
    if flow.hostname == MagicStrings.readRulesSentinalHostname {
      self.loadAndSetRules()
      return .drop
    }

    #if DEBUG
      if flow.hostname == MagicStrings.dumpLogsSentinalHostname {
        for (i, logs) in self.memoryLogs.withValue({ $0 }).chunked(into: 6).enumerated() {
          os_log("[G•] FILTER memory logs %d:\n%{public}s", i + 1, logs.joined(separator: "\n"))
        }
        return .drop
      }

      let target = (flow.target ?? "nil").prefix(25)
      self.logger.log("Decide flow `\(target)`, rules: \(self.protectionMode.shortDesc)")
    #endif

    if self.shouldRequestUpdate() {
      self.logger.log("request update, count: \(self.count)")
      return .needRules
    }

    return self.decideNewFlow(flow)
  }

  public mutating func handleRulesChanged() {
    self.logger.log(".handleRulesChanged() called")
    self.loadAndSetRules()
  }

  public mutating func startFilter() {
    self.logger.log("Starting filter")
    self.loadAndSetRules()
  }

  public func stopFilter(reason: NEProviderStopReason) {}
}

extension FilterProxy: FlowDecider {
  public func log(_ message: String) {
    self.logger.log(message)
  }

  public func debugLog(_ message: String) {
    self.logger.debug(message)
  }
}

// helpers

private func isGertrude(_ bundleId: String?) -> Bool {
  guard let bundleId else { return false }
  return bundleId == .gertrudeBundleIdLong || bundleId == .gertrudeBundleIdShort
}

// "exports" for filter

public typealias BlockRule = GertieIOS.BlockRule
public typealias FlowType = GertieIOS.FlowType
