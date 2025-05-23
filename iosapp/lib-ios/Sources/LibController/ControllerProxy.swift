import ConcurrencyExtras
import Dependencies
import LibClients
import NetworkExtension

@Sendable func updateRules(deps: ControllerProxy.Deps, notify: LockIsolated<() -> Void>) async {
  guard let vendorId = await deps.device.vendorId() else {
    deps.logger.log("no vendor id, skipping rule update")
    return
  }

  guard let disabled = deps.storage.loadDisabledBlockGroups() else {
    deps.logger.log("no stored block groups, skipping rule update")
    return
  }

  deps.logger.log("updating rules")
  guard let apiRules = try? await deps.api.fetchBlockRules(vendorId, disabled) else {
    deps.logger.log("failed to fetch rules")
    return
  }

  guard apiRules.count > 0 else {
    deps.logger.log("unexpected empty rules from api")
    return
  }
  let protectionMode = deps.storage.loadProtectionMode()
  let isSuspended = protectionMode?.isSuspended ?? false
  if !isSuspended {
    deps.recorder.uploadRemainingScreenshots()
  }

  let savedRules = protectionMode?.normalRules
  if apiRules != savedRules, !isSuspended {
    deps.logger.log("saving changed rules")
    deps.storage.saveProtectionMode(.normal(apiRules))
    notify.withValue { $0() }
  } else {
    deps.logger.log("rules unchanged or filter is currently suspended.")
  }
}

public class ControllerProxy {
  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.osLog) var logger
    @Dependency(\.suspendingClock) var clock
    @Dependency(\.device) var device
    @Dependency(\.storage) var storage
    @Dependency(\.recorder) var recorder
  }

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
    self.heartbeatTask = Task { [deps = self.deps, notify = self.notifyRulesChanged] in
      // make sure we've updated when the controller first starts
      deps.logger.log("first heartbeat rule update")
      await updateRules(deps: deps, notify: notify)
      try await deps.clock.sleep(for: initialDelay)
      deps.logger.log("second heartbeat rule update")
      await updateRules(deps: deps, notify: notify)

      // then check on schedule
      while true {
        try await deps.clock.sleep(for: interval)
        deps.logger.log("repeating heartbeat rule update")
        await updateRules(deps: deps, notify: notify)
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
