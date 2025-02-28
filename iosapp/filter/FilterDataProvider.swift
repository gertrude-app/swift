import Foundation
import LibCore
import LibFilter
import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
  let proxy = FilterProxy(protectionMode: .emergencyLockdown)

  override init() {
    super.init()
    os_log("[G•] FILTER init")
    #if DEBUG
      self.proxy.startHeartbeat(interval: .seconds(45))
    #else
      self.proxy.startHeartbeat(interval: .minutes(5))
    #endif
  }

  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    os_log("[G•] FILTER start")
    self.proxy.startFilter()
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
    let flowType: FlowType?

    if let browserFlow = flow as? NEFilterBrowserFlow {
      flowType = .browser
      url = browserFlow.url?.absoluteString
      os_log(
        "[G•] FILTER handle new BROWSER flow (data) : %{public}s",
        String(describing: browserFlow)
      )
    } else if let socketFlow = flow as? NEFilterSocketFlow {
      flowType = .socket
      hostname = socketFlow.remoteHostname
      os_log(
        "[G•] FILTER handle new SOCKET flow (data) : %{public}s",
        String(describing: socketFlow)
      )
    } else {
      flowType = nil
      os_log(
        "[G•] FILTER flow is NEITHER subclass (unreachable?) id: %{public}s",
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
      "[G•] FILTER flow verdict: %{public}s, hostname: %{public}s, url: %{public}s, sourceId: %{public}s",
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
