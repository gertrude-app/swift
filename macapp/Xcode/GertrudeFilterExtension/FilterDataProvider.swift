import Combine
import Core
import Filter
import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
  let store = FilterStore()
  var flowUserIds: [UUID: uid_t] = [:]
  var cancellables: Set<AnyCancellable> = []

  // give the FilterDataProvider a simple boolean it can
  // quickly check to decide if it needs to pass the decision
  // on to the store - the vast majority of the time, nothing
  // needs to be sent, and the filter is sometimes making a huge
  // number of decisions, so keeping this lookup as fast as possible
  // for the normal case is important
  var sendingBlockDecisions = false

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

    store.shouldSendBlockDecisions().sink { [weak self] in
      os_log("[G•] FILTER data provider: toggle send block decisions %{public}d", $0)
      self?.sendingBlockDecisions = $0
    }.store(in: &cancellables)
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
      #if DEBUG
        return .allow()
      #else
        return .drop()
      #endif
    case .allow:
      return .allow()
    case .none(let id):
      userId = id
    }

    let filterFlow = FilterFlow(flow, userId: userId)
    let decision = store.newFlowDecision(filterFlow, auditToken: flow.sourceAppAuditToken)

    switch decision {
    case .block(.defaultNotAllowed):
      if sendingBlockDecisions {
        store.sendBlocked(filterFlow, auditToken: flow.sourceAppAuditToken)
      }
      #if DEBUG
        return .allow()
      #else
        return .drop()
      #endif
    case .block:
      #if DEBUG
        return .allow()
      #else
        return .drop()
      #endif
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
    if flowUserIds.count > 100 {
      flowUserIds = [:]
    }

    let filterFlow = FilterFlow(flow, userId: userId)
    let decision = store.completedFlowDecision(
      filterFlow,
      readBytes: readBytes,
      auditToken: flow.sourceAppAuditToken
    )

    switch decision {
    case .block(.defaultNotAllowed):
      if sendingBlockDecisions {
        store.sendBlocked(filterFlow, auditToken: flow.sourceAppAuditToken)
      }
      #if DEBUG
        return .allow()
      #else
        return .drop()
      #endif
    case .block:
      #if DEBUG
        return .allow()
      #else
        return .drop()
      #endif
    case .allow:
      return .allow()
    }
  }

  deinit {
    store.sendExtensionStopping()
  }
}

extension FilterFlow {
  init(_ rawFlow: NEFilterFlow, userId: uid_t? = nil) {
    self.init(url: rawFlow.url?.absoluteString, description: rawFlow.description)
    self.userId = userId
  }
}
