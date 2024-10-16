import LibFilter
import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    os_log("[G•] start filter (data)")
    completionHandler(nil)
  }

  override func stopFilter(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    os_log("[G•] stop filter (data) reason: %{public}s", String(describing: reason))
    completionHandler()
  }

  override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
    var hostname: String?
    var url: String?
    let sourceId: String? = flow.sourceAppIdentifier
    if let browserFlow = flow as? NEFilterBrowserFlow {
      url = browserFlow.url?.absoluteString
      os_log("[G•] handle new BROWSER flow (data) : %{public}s", String(describing: browserFlow))
    } else if let socketFlow = flow as? NEFilterSocketFlow {
      hostname = socketFlow.remoteHostname
      os_log("[G•] handle new SOCKET flow (data) : %{public}s", String(describing: socketFlow))
    } else {
      os_log(
        "[G•] flow is NEITHER subclass (unreachable?) id: %{public}s",
        String(describing: flow.identifier)
      )
    }
    let shouldAllow = decideFlow(hostname: hostname, url: url, sourceId: sourceId)
    os_log(
      "[G•] decision: %{public}s, hostname: %{public}s, url: %{public}s, sourceId: %{public}s",
      shouldAllow ? "ALLOW" : "DROP",
      hostname ?? "(nil)",
      url ?? "(nil)",
      sourceId ?? "(nil)"
    )
    return shouldAllow ? .allow() : .drop()
  }
}
