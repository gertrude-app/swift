import ConcurrencyExtras
import Dependencies
import GertieIOS
import IOSRoute
import LibClients
import LibCore
import ManagedSettings
import NetworkExtension

public final class ControllerProxy: Sendable {
  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.osLog) var logger
    @Dependency(\.suspendingClock) var clock
    @Dependency(\.device) var device
    @Dependency(\.sharedStorage) var storage
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
  }

  private let deps = Deps()
  private let managedSettings = LockIsolated<ManagedSettingsStore?>(nil)
  // private let protectionMode = LockIsolated<ProtectionMode>(.emergencyLockdown)
  public let notifyRulesChanged = LockIsolated<() -> Void>(unimplemented("notifyRulesChanged"))

  public init() {
    self.deps.logger.setPrefix("CONTROLLER PROXY")
    // self.loadAndSetRules()
    self.deps.logger.setObserver { msg, isDebug in
      if isDebug { return }
      self.deps.storage.saveDebugLog("\(Date()) [G•] CONTROLLER PROXY \(msg.prefix(100))")
    }
    self.deps.logger.log("Initialized ControllerProxy")
  }

  // func loadAndSetRules() {
  //   let mode = self.deps.storage.loadProtectionMode()
  //   self.deps.logger.logReadProtectionMode(mode)
  //   mode.map { self.protectionMode.setValue($0) }
  // }
  //
  public func startFilter() -> Task<Void, Never> {
    self.deps.logger.log("starting filter")
    return Task {
      await self.deps.api.logEvent(id: "00ec3909", detail: "controller proxy: filter started")
      self.deps.logger.log("start filter refresh rules 1")
      await self.refreshRules()
      self.deps.logger.log("start filter refresh rules 2")
      try? await self.deps.clock.sleep(for: .seconds(15))
      await self.refreshRules()
      self.deps.logger.log("start filter refresh rules 3")
      try? await self.deps.clock.sleep(for: .seconds(15))
      await self.refreshRules()
    }
  }

  @discardableResult
  func refreshRules() async -> Bool {
    guard let vendorId = await self.deps.device.vendorId() else {
      self.deps.logger.log("no vendor id, skipping rule update")
      return false
    }
    if self.deps.storage.loadAccountConnection() != nil {
      return await self.refreshConnectedRules(vendorId)
    } else {
      return await self.refreshNormalRules(vendorId)
    }
  }

  func refreshConnectedRules(_ vendorId: UUID) async -> Bool {
    do {
      self.deps.logger.log("fetching rules from API")
      let config = try await self.deps.api.connectedRules(vendorId)
      guard config.blockRules.count > 0 else {
        self.deps.logger.log("unexpected empty rules from api (connected)")
        return false
      }
      let storedMode = self.deps.storage.loadProtectionMode() ?? .emergencyLockdown
      if storedMode == config.protectionMode {
        self.deps.logger.log("rules unchanged (connected)")
        return false
      }
      self.deps.logger.log("saving changed rules (connected)")
      self.deps.storage.saveProtectionMode(config.protectionMode)
      self.notifyRulesChanged.withValue { $0() }
      self.managedSettings.withValue {
        if let current = $0 {
          current.gertiePolicy = config.webPolicy
          $0 = current
        } else {
          let store = ManagedSettingsStore(named: .init(.gertrudeGroupId))
          store.gertiePolicy = config.webPolicy
          $0 = store
        }
      }
      return true
    } catch {
      self.deps.logger.log("failed to fetch connected rules: \(error)")
      return false
    }
  }

  func refreshNormalRules(_ vendorId: UUID) async -> Bool {
    self.managedSettings.setValue(nil)
    guard let disabled = self.deps.storage.loadDisabledBlockGroups() else {
      self.deps.logger.log("no stored block groups, skipping rule update")
      return false
    }

    do {
      self.deps.logger.log("fetching rules from API")
      let apiRules = try await deps.api.fetchBlockRules(vendorId, disabled)

      guard apiRules.count > 0 else {
        self.deps.logger.log("unexpected empty rules from api")
        return false
      }

      let savedRules = self.deps.storage.loadProtectionMode()?.normalRules
      if apiRules != savedRules {
        self.deps.logger.log("saving changed rules")
        self.deps.storage.saveProtectionMode(.normal(apiRules))
        self.notifyRulesChanged.withValue { $0() }
        return true
      } else {
        self.deps.logger.log("rules unchanged")
        return false
      }
    } catch {
      self.deps.logger.log("failed to fetch block rules: \(error)")
      return false
    }
  }

  @discardableResult
  public func stopFilter(reason: NEProviderStopReason) -> Task<Void, Never> {
    self.deps.logger.log("stopping filter")
    return Task { [api = self.deps.api] in
      await api.logEvent(id: "8e23bea2", detail: "filter stopped, reason: \(reason)")
    }
  }

  public func handleNewFlow(_ systemFlow: NEFilterFlow) async -> NEFilterControlVerdict {
    // CONVENTION: we get here when the filter sends a `.needsRules` verdict, indicating
    // that according to it's incremental "timer", it thinks it's time to update the rules
    // FIXME: check if we have internet!!! ...maybe in refreshRules?
    let rulesChanged = await self.refreshRules()
    let flow = self.toFilterFlow(systemFlow)
    return switch self.decideNewFlow(flow) {
    case .allow:
      .allow(withUpdateRules: rulesChanged)
    case .drop:
      .drop(withUpdateRules: rulesChanged)
    case .needRules:
      .drop(withUpdateRules: true) // should be unreachable
    }
  }
}

extension ControllerProxy: FlowDecider {
  public var calendar: Calendar { self.deps.calendar }
  public var now: Date { self.deps.now }
  public var protectionMode: LibCore.ProtectionMode {
    self.deps.storage.loadProtectionMode() ?? .emergencyLockdown
  }

  public func debugLog(_ message: String) {
    self.deps.logger.debug(message)
  }

  public func log(_ message: String) {
    self.deps.logger.log(message)
  }
}

extension ConnectedRules.Output {
  var protectionMode: ProtectionMode {
    .connected(self.blockRules, self.webPolicy)
  }
}

#if os(iOS)
  extension ManagedSettingsStore {
    var gertiePolicy: WebContentFilterPolicy? {
      get { self.webContent.blockedByFilter?.gertiePolicy }
      set { self.webContent.blockedByFilter = newValue.map(\.managedSettingsPolicy) }
    }
  }
#else
  class ManagedSettingsStore {
    struct Name {
      init(_ value: String) {}
    }

    private var _policy: WebContentFilterPolicy?
    init(named: Name) {}
    var gertiePolicy: WebContentFilterPolicy? {
      get { self._policy }
      set { self._policy = newValue }
    }
  }

  public class NEFilterControlVerdict {
    public class func allow(withUpdateRules: Bool) -> NEFilterControlVerdict { .init() }
    public class func drop(withUpdateRules: Bool) -> NEFilterControlVerdict { .init() }
    public class func updateRules() -> NEFilterControlVerdict { .init() }
  }
#endif
