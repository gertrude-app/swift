import Dependencies
import LibClients
import NetworkExtension

public class ControllerProxy {
  @Dependency(\.api) var api
  @Dependency(\.storage) var storage
  @Dependency(\.filter) var filter
  @Dependency(\.suspendingClock) var clock

  var heartbeatTask: Task<Void, Never>?

  public func startFilter() {
    self.heartbeatTask = Task { [weak self] in
      while true {
        try? await self?.clock.sleep(for: .minutes(60))
        await self?.receiveHeartbeat()
      }
    }
  }

  @discardableResult
  public func stopFilter(reason: NEProviderStopReason) -> Task<Void, Never> {
    Task {
      await self.api.logEvent(
        id: "8e23bea2",
        detail: "filter stopped, reason: \(reason)"
      )
    }
  }

  func receiveHeartbeat() async {
    try? await self.filter.sendFilterErrors()
    guard let apiRules = try? await self.api.fetchBlockRules() else {
      return
    }
    let savedRules = self.storage.loadBlockRules()
    if apiRules != savedRules {
      self.storage.saveBlockRules(apiRules)
      try? await self.filter.notifyRulesChanged()
    }
  }

  @discardableResult
  public func handleNewFlow(_ flow: NEFilterFlow) -> Task<Void, Never> {
    Task {
      await self.api.logEvent(
        id: "4d6edf26",
        detail: "unexpected handle new flow from FilterControlProvider"
      )
    }
  }

  public init() {}
}
