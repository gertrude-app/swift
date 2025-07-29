import ConcurrencyExtras
import Dependencies
import GertieIOS
import LibClients
import NetworkExtension

#if os(iOS)
  import ManagedSettings

  extension ManagedSettingsStore {
    var gertiePolicy: WebContentFilterPolicy? {
      get { self.webContent.blockedByFilter?.gertiePolicy }
      set { self.webContent.blockedByFilter = newValue.map(\.managedSettingsPolicy) }
    }
  }
#else
  struct ManagedSettingsStore {
    private var _policy: WebContentFilterPolicy?
    init(named: String) {}
    var gertiePolicy: WebContentFilterPolicy? {
      get { self._policy }
      set { self._policy = newValue }
    }
  }
#endif

@Sendable func updateRules(
  deps: ControllerProxy.Deps,
  notify: LockIsolated<() -> Void>
) async -> WebContentFilterPolicy? {
  guard let vendorId = await deps.device.vendorId() else {
    deps.logger.log("no vendor id, skipping rule update")
    return nil
  }

  let connected = deps.userDefaults.loadConnection() != nil

  if connected {
    guard let connectedRules = try? await deps.api.connectedRules(vendorId) else {
      deps.logger.log("failed to fetch rules (connected)")
      return nil
    }

    let apiRules = connectedRules.blockRules
    guard apiRules.count > 0 else {
      deps.logger.log("unexpected empty rules from api (connected)")
      return nil
    }

    let savedRules = deps.userDefaults.loadProtectionMode()?.normalRules
    if apiRules != savedRules {
      deps.logger.log("saving changed rules (connected)")
      deps.userDefaults.saveProtectionMode(.normal(apiRules))
      notify.withValue { $0() }
    } else {
      deps.logger.log("rules unchanged")
    }
    return connectedRules.webPolicy

  } else {

    guard let disabled = deps.userDefaults.loadDisabledBlockGroups() else {
      deps.logger.log("no stored block groups, skipping rule update")
      return nil
    }

    deps.logger.log("updating rules")
    guard let apiRules = try? await deps.api.fetchBlockRules(vendorId, disabled) else {
      deps.logger.log("failed to fetch rules")
      return nil
    }

    guard apiRules.count > 0 else {
      deps.logger.log("unexpected empty rules from api")
      return nil
    }

    let savedRules = deps.userDefaults.loadProtectionMode()?.normalRules
    if apiRules != savedRules {
      deps.logger.log("saving changed rules")
      deps.userDefaults.saveProtectionMode(.normal(apiRules))
      notify.withValue { $0() }
    } else {
      deps.logger.log("rules unchanged")
    }
    return nil
  }
}

public class ControllerProxy {
  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.osLog) var logger
    @Dependency(\.suspendingClock) var clock
    @Dependency(\.device) var device
    @Dependency(\.sharedUserDefaults) var userDefaults
  }

  private let managedSettings =
    LockIsolated<ManagedSettingsStore>(
      ManagedSettingsStore(named: .init("com.netrivet.gertrude.app"))
    )
  private let deps = Deps()
  private var heartbeatTask: Task<Void, Error>?
  public let notifyRulesChanged =
    LockIsolated<() -> Void>(unimplemented("ControllerProxy.notifyRulesChanged"))

  public init() {
    self.deps.logger.setPrefix("CONTROLLER PROXY")
  }

  public func startFilter() {
    self.deps.logger.log("starting filter")
    Task { [api = self.deps.api] in
      await api.logEvent(id: "00ec3909", detail: "controller proxy: filter started")
    }
  }

  public func startHeartbeat(initialDelay: Duration, interval: Duration) {
    self.heartbeatTask = Task { [
      deps = self.deps,
      notify = self.notifyRulesChanged,
      managedSettings = self.managedSettings
    ] in
      // make sure we've updated when the controller first starts
      deps.logger.log("first heartbeat rule update")
      await handleWebPolicy(
        updateRules(deps: deps, notify: notify),
        deps: deps,
        managedSettings: managedSettings
      )
      try await deps.clock.sleep(for: initialDelay)
      deps.logger.log("second heartbeat rule update")
      await handleWebPolicy(
        updateRules(deps: deps, notify: notify),
        deps: deps,
        managedSettings: managedSettings
      )

      // then check on schedule
      while true {
        try await deps.clock.sleep(for: interval)
        deps.logger.log("repeating heartbeat rule update")
        await handleWebPolicy(
          updateRules(deps: deps, notify: notify),
          deps: deps,
          managedSettings: managedSettings
        )
      }
    }
  }

  @discardableResult
  public func stopFilter(reason: NEProviderStopReason) -> Task<Void, Never> {
    self.deps.logger.log("stopping filter")
    return Task { [api = self.deps.api] in
      await api.logEvent(id: "8e23bea2", detail: "filter stopped, reason: \(reason)")
    }
  }

  @discardableResult
  public func handleNewFlow(_ flow: NEFilterFlow) -> Task<Void, Never> {
    self.deps.logger.log("unexpected handle new flow")
    return Task { [api = self.deps.api] in
      await api.logEvent(
        id: "4d6edf26",
        detail: "unexpected error handle new flow from FilterControlProvider"
      )
    }
  }
}

@Sendable func handleWebPolicy(
  _ newPolicy: WebContentFilterPolicy?,
  deps: ControllerProxy.Deps,
  managedSettings: LockIsolated<ManagedSettingsStore>
) {
  let oldPolicy = managedSettings.withValue { $0.gertiePolicy }
  switch (oldPolicy, newPolicy) {
  case (.none, .some(let policy)):
    deps.logger.log("applying new web policy")
    managedSettings.withValue { $0.gertiePolicy = policy }
  case (.some(let prevPolicy), .some(let nextPolicy)) where prevPolicy != nextPolicy:
    deps.logger.log("applying changed web policy")
    managedSettings.withValue { $0.gertiePolicy = nextPolicy }
  default:
    break // leave old policy in place in every other combination for safety
  }
}
