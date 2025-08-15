import Foundation
import LibCore
import LibFilter
import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
  var proxy = FilterProxy(protectionMode: .emergencyLockdown)

  override init() {
    super.init()
    os_log("[G•] FILTER init")
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

  // NB: from logging, it appears that this can get called from different threads
  // although big bursts of near simultaneous network connections seem to to be
  // handled by the same thread, instead of being interleaved, seems more like the
  // system puts the process to sleep after inactivity, then it wakes up on a new thread
  // so it's probably the correct mental model to consider this a single-threaded
  override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
    let verdict = self.proxy.decideFlow(flow)
    return switch verdict {
    case .allow: .allow()
    case .drop: .drop()
    case .needRules: .needRules()
    }
  }

  override func handleRulesChanged() {
    self.proxy.handleRulesChanged()
  }
}
