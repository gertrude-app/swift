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

  // right now we just log in verbose mode whenever we're streaming blocks
  // but in the future, we might have a separate boolean and an app->filter message
  // to enable this for a specific period
  var verboseLogging: Bool { sendingBlockDecisions }

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
      if let error = errorOrNil {
        os_log(
          "[G•] FILTER data provider: error applying filter settings: %{public}s",
          error.localizedDescription
        )
      }
    }

    self.store.shouldSendBlockDecisions().sink { [weak self] in
      os_log("[G•] FILTER data provider: toggle send block decisions %{public}d", $0)
      self?.sendingBlockDecisions = $0
    }.store(in: &self.cancellables)
  }

  override func stopFilter(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    os_log("[G•] FILTER data provider: filter stopped, reason: %{public}s", "\(reason)")
    completionHandler()
  }

  override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
    let userId: uid_t
    let earlyUserDecision = self.store.earlyUserDecision(auditToken: flow.sourceAppAuditToken)
    if self.verboseLogging {
      os_log("[D•] FILTER received new flow: %{public}s", "\(flow.description)")
      os_log("[D•] FILTER early user decision: %{public}@", "\(earlyUserDecision)")
    }

    let filterFlow: FilterFlow

    switch earlyUserDecision {
    case .block:
      return dropNewFlow()
    case .allow:
      return .allow()
    case .blockDuringDowntime(let id):
      userId = id
      filterFlow = FilterFlow(flow, userId: userId)
      if filterFlow.isFromGertrude || filterFlow.isSystemUiServerInternal {
        if self.verboseLogging {
          os_log(
            "[D•] FILTER ALLOW during downtime, bundleId: %{public}s",
            "\(filterFlow.bundleId ?? "(nil)")"
          )
        }
        return .allow()
      } else {
        if self.verboseLogging {
          os_log(
            "[D•] FILTER DROP during downtime, bundleId: %{public}s",
            "\(filterFlow.bundleId ?? "(nil)")"
          )
        }
        return dropNewFlow()
      }
    case .none(let id):
      userId = id
      filterFlow = FilterFlow(flow, userId: userId)
    }

    self.store.logAppRequest(from: filterFlow.bundleId)

    let decision = self.store.newFlowDecision(filterFlow, auditToken: flow.sourceAppAuditToken)
    if self.verboseLogging {
      switch decision {
      case .some(let decision):
        os_log("[D•] FILTER new flow decision: %{public}@", "\(decision)")
      case .none:
        os_log("[D•] FILTER new flow decision: DEFER")
      }
    }

    switch decision {
    case .block:
      if self.sendingBlockDecisions {
        self.store.sendBlocked(filterFlow, auditToken: flow.sourceAppAuditToken)
      }
      return dropNewFlow()
    case .allow:
      return .allow()
    case nil:
      self.flowUserIds[flow.identifier] = userId
      return .filterDataVerdict(
        withFilterInbound: false,
        peekInboundBytes: Int.max,
        filterOutbound: true,
        peekOutboundBytes: 1024
      )
    }
  }

  override func handleOutboundData(
    from flow: NEFilterFlow,
    readBytesStartOffset _: Int,
    readBytes: Data
  ) -> NEFilterDataVerdict {
    let userId = self.flowUserIds.removeValue(forKey: flow.identifier)

    // safeguard: prevent memory leak
    if self.flowUserIds.count > 100 {
      self.flowUserIds = [:]
    }

    var filterFlow = FilterFlow(flow, userId: userId)
    let decision = self.store.completedFlowDecision(
      &filterFlow,
      readBytes: readBytes,
      auditToken: flow.sourceAppAuditToken
    )

    if self.verboseLogging {
      os_log("[D•] FILTER outbound flow: %{public}s", "\(filterFlow.shortDescription)")
      os_log("[D•] FILTER outbound flow decision: %{public}@", "\(decision)")
      os_log("[D•] FILTER outbound flow bytes: %{public}s", bytesToAscii(readBytes))
    }

    switch decision {
    case .block:
      if self.sendingBlockDecisions {
        self.store.sendBlocked(filterFlow, auditToken: flow.sourceAppAuditToken)
      }
      return dropFlow()
    case .allow:
      return .allow()
    }
  }

  deinit {
    store.sendExtensionStopping()
  }
}

private func dropFlow() -> NEFilterDataVerdict {
  #if DEBUG
    return .allow()
  #else
    return .drop()
  #endif
}

private func dropNewFlow() -> NEFilterNewFlowVerdict {
  #if DEBUG
    return .allow()
  #else
    return .drop()
  #endif
}

extension FilterFlow {
  init(_ rawFlow: NEFilterFlow, userId: uid_t? = nil) {
    self.init(url: rawFlow.url?.absoluteString, description: rawFlow.description)
    self.userId = userId
  }
}
