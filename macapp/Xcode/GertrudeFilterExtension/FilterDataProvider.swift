import Combine
import Core
import Filter
import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
  let proxy = FilterProxy()

  override init() {
    super.init()
    self.proxy.sendExtensionStarted()
  }

  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    self.apply(self.proxy.filterSettings()) { error in
      completionHandler(error)
      if let error {
        os_log(
          "[G•] FILTER data provider: error applying filter settings: %{public}s",
          error.localizedDescription
        )
      }
    }
    self.proxy.startFilter()
  }

  override func stopFilter(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    os_log("[G•] FILTER data provider: filter stopped, reason: %{public}s", "\(reason)")
    completionHandler()
  }

  override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
    self.proxy.handleNewFlow(flow.dto)
  }

  override func handleOutboundData(
    from flow: NEFilterFlow,
    readBytesStartOffset _: Int,
    readBytes: Data
  ) -> NEFilterDataVerdict {
    self.proxy.handleOutboundData(from: flow.dto, readBytes: readBytes)
  }

  deinit {
    self.proxy.sendExtensionStopping()
  }
}
