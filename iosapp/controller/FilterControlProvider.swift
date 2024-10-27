import NetworkExtension
import LibController
import os.log

class FilterControlProvider: NEFilterControlProvider {
  let proxy = ControllerProxy()
  
  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    self.proxy.startFilter()
    completionHandler(nil)
  }

  override func stopFilter(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    self.proxy.stopFilter(reason: reason)
    os_log("[G•] stop filter (control) reason: %{public}s", String(describing: reason))
    completionHandler()
  }

  override func handleNewFlow(
    _ flow: NEFilterFlow,
    completionHandler: @escaping (NEFilterControlVerdict) -> Void
  ) {
    self.proxy.handleNewFlow(flow)
    completionHandler(.allow(withUpdateRules: false))
  }
}
