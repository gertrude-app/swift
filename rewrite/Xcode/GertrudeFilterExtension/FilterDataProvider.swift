import Core
import Filter
import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
  let store = FilterStore()
  var flowUserIds: [UUID: uid_t] = [:]

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

    switch store.newFlowDecision(
      FilterFlow(flow, userId: userId),
      auditToken: flow.sourceAppAuditToken
    ) {
    case .block:
      return .drop()
    case .allow:
      return .allow()
    case nil:
      flowUserIds[flow.identifier] = userId
      return .filterDataVerdict(
        withFilterInbound: false,
        peekInboundBytes: Int.max,
        filterOutbound: true,
        peekOutboundBytes: 250
      )
    }
  }

  override func handleOutboundData(
    from flow: NEFilterFlow,
    readBytesStartOffset _: Int,
    readBytes: Data
  ) -> NEFilterDataVerdict {
    let userId = flowUserIds.removeValue(forKey: flow.identifier)

    // safeguard: prevent memory leak
    if flowUserIds.length > 100 {
      flowUserIds = [:]
    }

    let decision = store.completedFlowDecision(
      FilterFlow(flow, userId: userId),
      readBytes: readBytes,
      auditToken: flow.sourceAppAuditToken
    )

    switch decision {
    case .block:
      return .drop()
    case .allow:
      return .allow()
    }
  }
}

extension FilterFlow {
  init(_ rawFlow: NEFilterFlow, userId: uid_t? = nil) {
    self.init(url: rawFlow.url?.absoluteString, description: rawFlow.description)
    self.userId = userId
  }
}
