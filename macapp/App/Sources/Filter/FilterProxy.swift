import Combine
import Core
import Foundation
import NetworkExtension
import os.log

/// A proxy for the FilterDataProvider, which is impossible to test
/// and now mostly forwards functionality to this class, passing DTOs
/// where it traffics in types that are not constructable in tests.
public class FilterProxy {
  #if !DEBUG
    let store: FilterStore
  #else
    var store: FilterStore
  #endif

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
  var verboseLogging: Bool { self.sendingBlockDecisions }

  public func handleNewFlow(_ flow: NEFilterFlow.DTO) -> NEFilterNewFlowVerdict {
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
    case .block(.urlMessage(let message)):
      self.store.send(urlMessage: message)
      return .drop()
    case .block:
      if self.sendingBlockDecisions {
        self.store.sendBlocked(filterFlow, auditToken: flow.sourceAppAuditToken)
      }
      return dropNewFlow()
    case .allow(.fromGertrudeApp):
      self.store.send(urlMessage: .alive(userId))
      return .allow()
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

  public func handleOutboundData(
    from flow: NEFilterFlow.DTO,
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

  public func startFilter() {
    self.store.shouldSendBlockDecisions().sink { [weak self] in
      os_log("[G•] FILTER data provider: toggle send block decisions %{public}d", $0)
      self?.sendingBlockDecisions = $0
    }.store(in: &self.cancellables)
  }

  public func filterSettings() -> NEFilterSettings {
    let networkRule = NENetworkRule(
      remoteNetwork: nil,
      remotePrefix: 0,
      localNetwork: nil,
      localPrefix: 0,
      protocol: .any,
      direction: .outbound
    )

    let filterRule = NEFilterRule(networkRule: networkRule, action: .filterData)
    return NEFilterSettings(rules: [filterRule], defaultAction: .allow)
  }

  public func sendExtensionStopping() {
    self.store.sendExtensionStopping()
  }

  public func sendExtensionStarted() {
    self.store.sendExtensionStarted()
  }

  public init(store: FilterStore = .init()) {
    self.store = store
  }
}

public extension NEFilterFlow {
  /// A data transfer object for `NEFilterFlow`.
  /// NB: the original object has more data
  struct DTO {
    let identifier: UUID
    let sourceAppAuditToken: Data?
    let description: String
    let url: URL?

    public init(
      identifier: UUID = .init(),
      sourceAppAuditToken: Data? = nil,
      description: String,
      url: URL? = nil
    ) {
      self.identifier = identifier
      self.sourceAppAuditToken = sourceAppAuditToken
      self.description = description
      self.url = url
    }
  }

  var dto: DTO { .init(
    identifier: self.identifier,
    sourceAppAuditToken: self.sourceAppAuditToken,
    description: self.description,
    url: self.url
  ) }
}

extension FilterFlow {
  init(_ flow: NEFilterFlow.DTO, userId: uid_t? = nil) {
    self.init(url: flow.url?.absoluteString, description: flow.description)
    self.userId = userId
  }
}

private func dropFlow() -> NEFilterDataVerdict {
  #if DEBUG
    return getuid() < 500 ? .allow() : .drop()
  #else
    return .drop()
  #endif
}

private func dropNewFlow() -> NEFilterNewFlowVerdict {
  #if DEBUG
    return getuid() < 500 ? .allow() : .drop()
  #else
    return .drop()
  #endif
}
