import Filter
import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
  let store = FilterStore()

  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    let networkRule = NENetworkRule(
      remoteNetwork: nil,
      remotePrefix: 0,
      localNetwork: nil,
      localPrefix: 0,
      protocol: .any,
      direction: .outbound
    )

    let filterRule = NEFilterRule(networkRule: networkRule, action: .filterData)
    let filterSettings = NEFilterSettings(rules: [filterRule], defaultAction: .allow)

    apply(filterSettings) { errorOrNil in
      completionHandler(errorOrNil)
    }
  }

  override func stopFilter(
    with _: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }

  override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
    let userId: uid_t
    switch store.earlyUserDecision(auditToken: flow.sourceAppAuditToken) {
    case .block:
      return .drop()
    case .allow:
      return .allow()
    case .none(let id):
      userId = id
    }

    return .allow() // temp
    // switch store.newFlowDecision(FilterFlow(flow, userId: userId)) {
    // case .block:
    //   return .drop()
    // case .allow:
    //   return .allow()
    // case .defer:
    //   return .filterDataVerdict(
    //     withFilterInbound: false,
    //     peekInboundBytes: Int.max,
    //     filterOutbound: true,
    //     peekOutboundBytes: 250
    //   )
    // }
  }

  override func handleOutboundData(
    from rawFlow: NEFilterFlow,
    readBytesStartOffset offset: Int,
    readBytes: Data
  ) -> NEFilterDataVerdict {
    .allow()
  }
}
