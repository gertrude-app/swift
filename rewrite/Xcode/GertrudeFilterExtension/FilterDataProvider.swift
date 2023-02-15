import Filter
import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    os_log("gertie-rewrite: filter init %{public}@", Filter().text)
    completionHandler(nil)
  }

  override func stopFilter(
    with _: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    // Add code to clean up filter resources.
    completionHandler()
  }

  override func handleNewFlow(_: NEFilterFlow) -> NEFilterNewFlowVerdict {
    // Add code to determine if the flow should be dropped or not, downloading new rules if required.
    .allow()
  }
}
