import ConcurrencyExtras
import Dependencies
import LibClients
import NetworkExtension

@Sendable
func updateRules(logger: OsLogClient, notifier: LockIsolated<() -> Void>) async {
  @Dependency(\.api) var api
  @Dependency(\.device) var device
  @Dependency(\.storage) var storage

  guard let vendorId = device.vendorId else {
    logger.log("no vendor id, skipping rule update")
    return
  }

  guard let disabled = storage.loadDisabledBlockGroups() else {
    logger.log("no stored block groups, skipping rule update")
    return
  }

  logger.log("updating rules")
  guard let apiRules = try? await api.fetchBlockRules(vendorId, disabled) else {
    logger.log("failed to fetch rules")
    return
  }

  guard apiRules.count > 0 else {
    logger.log("unexpected empty rules from api")
    return
  }

  let savedRules = storage.loadProtectionMode()?.normalRules
  if apiRules != savedRules {
    logger.log("saving changed rules")
    storage.saveProtectionMode(.normal(apiRules))
    notifier.withValue { $0() }
  } else {
    logger.log("rules unchanged")
  }
}

public class ControllerProxy {
  @Dependency(\.api) var api
  @Dependency(\.osLog) var logger

  private var heartbeatTask: Task<Void, Error>?

  public let notifyRulesChanged: LockIsolated<() -> Void> =
    LockIsolated(unimplemented("ControllerProxy.notifyRulesChanged"))

  public init() {
    self.logger.setPrefix("CONTROLLER PROXY")
  }

  public func startFilter() {
    self.logger.log("starting filter")
    Task { [api = self.api] in
      await api.logEvent(id: "00ec3909", detail: "controller proxy: filter started")
    }
  }

  public func startHeartbeat(initialDelay: Duration, interval: Duration) {
    self.heartbeatTask = Task { [logger = self.logger, notifier = self.notifyRulesChanged] in
      await updateRules(logger: logger, notifier: notifier)
    }
  }

  @discardableResult
  public func stopFilter(reason: NEProviderStopReason) -> Task<Void, Never> {
    self.logger.log("stopping filter")
    return Task { [api = self.api] in
      await api.logEvent(id: "8e23bea2", detail: "filter stopped, reason: \(reason)")
    }
  }

  @discardableResult
  public func handleNewFlow(_ flow: NEFilterFlow) -> Task<Void, Never> {
    self.logger.log("unexpected handle new flow")
    return Task { [api = self.api] in
      await api.logEvent(
        id: "4d6edf26",
        detail: "unexpected handle new flow from FilterControlProvider"
      )
    }
  }
}
