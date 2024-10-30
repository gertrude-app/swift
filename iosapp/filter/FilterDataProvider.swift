import Foundation
import LibCore
import LibFilter
import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
  var heartbeatTask: Task<Void, Never>?
  let proxy = FilterProxy(rules: BlockRule.defaults, loadRules: {
    guard let data = UserDefaults.gertrude.data(forKey: .blockRulesStorageKey) else {
      os_log("[G•] FIlTER: no rules found")
      return nil
    }
    do {
      let rules = try JSONDecoder().decode([BlockRule].self, from: data)
      os_log("[G•] FILTER read %{public}d rules", rules.count)
      return rules
    } catch {
      os_log("[G•] FIlTER ERROR decoding rules: %{public}s", String(reflecting: error))
      return nil
    }
  })

  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    os_log("[G•] FILTER start")
    self.proxy.startFilter()
    self.heartbeatTask = Task { [weak self] in
      while true {
        try? await Task.sleep(for: .seconds(60 * 5))
        self?.proxy.receiveHeartbeat()
        os_log("[G•] send heartbeat")
      }
    }
    completionHandler(nil)
  }

  override func stopFilter(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    os_log("[G•] FILTER stop reason: %{public}s", String(describing: reason))
    self.proxy.stopFilter(reason: reason)
    completionHandler()
  }

  override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
    var hostname: String?
    var url: String?
    let bundleId: String? = flow.sourceAppIdentifier
    let flowType: FilterProxy.FlowType?

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

    let verdict = self.proxy.decideFlow(
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

  override func handleRulesChanged() {
    self.proxy.handleRulesChanged()
  }
}
