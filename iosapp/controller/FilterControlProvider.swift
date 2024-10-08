import NetworkExtension
import os.log

class FilterControlProvider: NEFilterControlProvider {

  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    os_log("[G•] start filter (control)")
    completionHandler(nil)
  }

  override func stopFilter(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    os_log("[G•] stop filter (control) reason: %{public}s", String(describing: reason))
    completionHandler()
  }

  override func handleNewFlow(
    _ flow: NEFilterFlow,
    completionHandler: @escaping (NEFilterControlVerdict) -> Void
  ) {
    completionHandler(.allow(withUpdateRules: false))
  }
}
