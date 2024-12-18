import Dependencies
import LibClients
import NetworkExtension

public class ControllerProxy {
  @Dependency(\.api) var api
  @Dependency(\.storage) var storage
  @Dependency(\.suspendingClock) var clock

  var heartbeatTask: Task<Void, Never>?
  public var notifyRulesChanged: () -> Void = unimplemented("ControllerProxy.notifyRulesChanged")

  public func startFilter() {
    self.heartbeatTask = Task { [weak self] in
      // make sure we've fetched when the controller first starts
      await self?.receiveHeartbeat()
      try? await self?.clock.sleep(for: .minutes(1))
      await self?.receiveHeartbeat()

      // then check every hour
      while true {
        #if DEBUG
          try? await self?.clock.sleep(for: .minutes(5))
        #else
          try? await self?.clock.sleep(for: .minutes(60))
        #endif
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
    guard let apiRules = try? await self.api.fetchBlockRules() else {
      return
    }
    let savedRules = self.storage.loadBlockRules()
    if apiRules != savedRules {
      self.storage.saveBlockRules(apiRules)
      self.notifyRulesChanged()
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
