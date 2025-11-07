import LibController
import NetworkExtension
import os.log

class FilterControlProvider: NEFilterControlProvider {
  let proxy = ControllerProxy()

  override init() {
    super.init()
    self.proxy.notifyRulesChanged.setValue { [weak self] in
      self?.notifyRulesChanged()
    }
    os_log("[G•] CONTROLLER init")
  }

  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    os_log("[G•] CONTROLLER start")
    self.proxy.startFilter()
    completionHandler(nil)
  }

  override func stopFilter(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void,
  ) {
    self.proxy.stopFilter(reason: reason)
    os_log("[G•] CONTROLLER stop reason: %{public}s", String(describing: reason))
    completionHandler()
  }

  override func handleNewFlow(_ flow: NEFilterFlow) async -> NEFilterControlVerdict {
    await self.proxy.handleNewFlow(flow)
  }
}
