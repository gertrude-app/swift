import Foundation
import LibCore
import LibFilter
import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
  var heartbeatTask: Task<Void, Never>?
  let manager = FilterManager(rules: [], loadRules: {
    guard let data = UserDefaults.gertrude.data(forKey: .blockRulesStorageKey) else {
      os_log("[G•] ERROR: no rules found")
      return .failure(.noRulesFound)
    }
    do {
      let rules = try JSONDecoder().decode([BlockRule].self, from: data)
      os_log("[G•] read %{public}d rules", rules.count)
      return .success(rules)
    } catch {
      os_log("[G•] ERROR decoding rules: %{public}s", String(reflecting: error))
      return .failure(.rulesDecodeFailed)
    }
  })

  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    os_log("[G•] start filter (data)")
    self.manager.startFilter()
    self.heartbeatTask = Task { [weak self] in
      while true {
        try? await Task.sleep(for: .seconds(60 * 5))
        self?.manager.receiveHeartbeat()
        os_log("[G•] send heartbeat")
      }
    }
    completionHandler(nil)
  }

  override func stopFilter(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    os_log("[G•] stop filter (data) reason: %{public}s", String(describing: reason))
    self.manager.stopFilter(reason: reason)
    completionHandler()
  }

  override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
    var hostname: String?
    var url: String?
    let bundleId: String? = flow.sourceAppIdentifier
    let flowType: FilterManager.FlowType?

    if let browserFlow = flow as? NEFilterBrowserFlow {
      flowType = .browser
      url = browserFlow.url?.absoluteString
      os_log("[G•] handle new BROWSER flow (data) : %{public}s", String(describing: browserFlow))
    } else if let socketFlow = flow as? NEFilterSocketFlow {
      flowType = .socket
      hostname = socketFlow.remoteHostname
      os_log("[G•] handle new SOCKET flow (data) : %{public}s", String(describing: socketFlow))
    } else {
      flowType = nil
      os_log(
        "[G•] flow is NEITHER subclass (unreachable?) id: %{public}s",
        String(describing: flow.identifier)
      )
    }

    let verdict = self.manager.decideFlow(
      hostname: hostname,
      url: url,
      bundleId: bundleId,
      flowType: flowType
    )

    os_log(
      "[G•] flow verdict: %{public}s, hostname: %{public}s, url: %{public}s, sourceId: %{public}s",
      verdict.description,
      hostname ?? "(nil)",
      url ?? "(nil)",
      bundleId ?? "(nil)"
    )

    return switch verdict {
    case .allow: .allow()
    case .drop: .drop()
    }
  }
}
