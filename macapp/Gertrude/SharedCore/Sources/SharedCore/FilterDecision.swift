import Foundation
import Gertie

/**
 * FilterDecision is an entity-agnostic, stripped down version of a NetworkDecision.
 * The filter is in the perf hot-path, so needs to run with the smallest possible
 * types -- so it has no need to know about protected user ids, and other aspects
 * of NetworkDecision. This struct models the bare minimum of what the filter needs
 * to communicate decisions across XPC. The mac app can translate into entities.
 */
public struct FilterDecision: Equatable, Codable {
  public let id: UUID
  public var verdict: NetworkDecisionVerdict = .block
  public var reason: NetworkDecisionReason = .defaultNotAllowed
  public var count: Int
  public var app: AppDescriptor?
  public var filterFlow: FilterFlow?
  public var responsibleKeyId: UUID?
  public var createdAt: Date

  public var ipProtocol: IpProtocol? { filterFlow?.ipProtocol }
  public var hostname: String? { filterFlow?.hostname }
  public var ipAddress: String? { filterFlow?.ipAddress }
  public var url: String? { filterFlow?.url }

  public var bundleId: String? {
    // currently, it's critical to prefer the app's bundle id
    // because the RootAppQuery can resolve a different bundle id
    // from the flow's bundle id, and it's the app's bundle id
    // that is tested by the decision maker, so we must report
    // the bundle id from the app (if present) to make sure that
    // keys scoped to apps are properly created and actually work.
    // at some point i really need to deeply re-think whether the
    // whole concept of the root app query is even worth it...
    app?.bundleId ?? filterFlow?.bundleId
  }

  public init(
    id: UUID = UUID(),
    verdict: NetworkDecisionVerdict = .block,
    reason: NetworkDecisionReason = .defaultNotAllowed,
    count: Int = 1,
    app: AppDescriptor? = nil,
    filterFlow: FilterFlow? = nil,
    responsibleKeyId: UUID? = nil,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.verdict = verdict
    self.reason = reason
    self.count = count
    self.app = app
    self.filterFlow = filterFlow
    self.responsibleKeyId = responsibleKeyId
    self.createdAt = createdAt
  }
}

// extensions

extension FilterDecision: CustomStringConvertible {
  public var target: String? {
    url ?? hostname ?? ipAddress
  }

  public var description: String {
    var desc = ""
    switch verdict {
    case .allow:
      desc = "ALLOW"
    case .block:
      desc = "BLOCK"
    }

    if let host = filterFlow?.hostname {
      desc += " request to `\(host)`"
    } else {
      desc += " request to `\(filterFlow?.ipAddress ?? "<missing>")`"
    }

    if let proto = filterFlow?.ipProtocol?.description {
      desc += " \(proto)"
    }

    desc += " because \(reason)"

    if let url = filterFlow?.url {
      desc += " [url: \(url)]"
    }

    if let app = app {
      desc += " from app \(String(describing: app))"
    }

    if let userId = filterFlow?.userId {
      desc += " user: \(userId)"
    }

    return desc
  }
}
