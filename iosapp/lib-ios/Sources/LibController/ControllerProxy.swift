import Dependencies
import LibClients
import NetworkExtension

public class ControllerProxy {
  @Dependency(\.api) var api
  @Dependency(\.device) var device
  @Dependency(\.osLog) var logger
  @Dependency(\.storage) var storage
  @Dependency(\.suspendingClock) var clock

  var heartbeatTask: Task<Void, Error>?
  public var notifyRulesChanged: () -> Void = unimplemented("ControllerProxy.notifyRulesChanged")

  public init() {
    self.logger.setPrefix("CONTROLLER PROXY")
  }

  public func startFilter() {
    self.logger.log("starting filter")
    Task {
      await self.api.logEvent(
        id: "00ec3909",
        detail: "controller proxy: filter started"
      )
    }
  }

  public func startHeartbeat(initialDelay: Duration, interval: Duration) {
    self.heartbeatTask = Task { [weak self] in
      // make sure we've updated when the controller first starts
      self?.logger.log("first heartbeat rule update")
      await self?.updateRules()
      try await self?.clock.sleep(for: initialDelay)
      self?.logger.log("second heartbeat rule update")
      await self?.updateRules()

      // then check on schedule
      while true {
        try await self?.clock.sleep(for: interval)
        self?.logger.log("repeating heartbeat rule update")
        await self?.updateRules()
      }
    }
  }

  @discardableResult
  public func stopFilter(reason: NEProviderStopReason) -> Task<Void, Never> {
    self.logger.log("stopping filter")
    return Task {
      await self.api.logEvent(
        id: "8e23bea2",
        detail: "filter stopped, reason: \(reason)"
      )
    }
  }

  func updateRules() async {
    guard let vendorId = self.device.vendorId else {
      self.logger.log("no vendor id, skipping rule update")
      return
    }

    guard let disabled = self.storage.loadDisabledBlockGroups() else {
      self.logger.log("no stored block groups, skipping rule update")
      return
    }

    self.logger.log("updating rules")
    guard let apiRules = try? await self.api.fetchBlockRules(vendorId, disabled) else {
      self.logger.log("failed to fetch rules")
      return
    }

    guard apiRules.count > 0 else {
      self.logger.log("unexpected empty rules from api")
      return
    }

    let savedRules = self.storage.loadProtectionMode()?.normalRules
    if apiRules != savedRules {
      self.logger.log("saving changed rules")
      self.storage.saveProtectionMode(.normal(apiRules))
      self.notifyRulesChanged()
    } else {
      self.logger.log("rules unchanged")
    }
  }

  @discardableResult
  public func handleNewFlow(_ flow: NEFilterFlow) -> Task<Void, Never> {
    self.logger.log("unexpected handle new flow")
    return Task {
      await self.api.logEvent(
        id: "4d6edf26",
        detail: "unexpected error handle new flow from FilterControlProvider"
      )
    }
  }
}
