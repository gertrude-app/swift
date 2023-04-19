import Core
import Foundation
import os.log // temp
import Shared

public extension NetworkFilter {

  func newFlowDecision(_ flow: FilterFlow, auditToken: Data? = nil) -> FilterDecision
    .FromFlow? {
    if let decision = flowDecision(flow, auditToken: auditToken, canDefer: true) {
      return logged(decision, from: flow)
    }
    return nil
  }

  func completedFlowDecision(
    _ flow: FilterFlow,
    readBytes: Data,
    auditToken: Data? = nil
  ) -> FilterDecision.FromFlow {
    var flow = flow
    if flow.url == nil {
      flow.parseOutboundData(byteString: bytesToString(readBytes))
    }
    let decision = flowDecision(flow, auditToken: auditToken, canDefer: false) ??
      .block(.defaultNotAllowed)
    return logged(decision, from: flow)
  }

  private func flowDecision(
    _ flow: FilterFlow,
    auditToken: Data?,
    canDefer: Bool
  ) -> FilterDecision.FromFlow? {

    if flow.isDnsRequest {
      return .allow(.dnsRequest)
    }

    if flow.bundleId == ".com.apple.systemuiserver", flow.isPrivateNetwork {
      // special allowance for system app that causes menubar flakiness if blocked
      return .allow(.systemUiServerInternal)
    }

    if flow.bundleId?.contains("com.netrivet.gertrude.app") == true {
      return .allow(.fromGertrudeApp)
    }

    guard let userId = flow.userId ?? security.userIdFromAuditToken(auditToken) else {
      return .block(.missingUserId)
    }

    let app = appDescriptor(for: flow.bundleId ?? "", auditToken: auditToken)
    if activeSuspension(for: userId, permits: app) {
      return .allow(.filterSuspended)
    }

    let keys = state.userKeys[userId] ?? []
    guard !keys.isEmpty else {
      return .block(.noUserKeys)
    }

    for filterKey in keys {
      switch filterKey.key {

      case .domain(domain: let domain, scope: let scope):
        if let hostname = flow.hostname, scope.permits(app),
           domain.matches(hostname: hostname) {
          return .allow(.permittedByKey(filterKey.id))
        }

      case .anySubdomain(domain: let domain, scope: let scope):
        if let hostname = flow.hostname,
           scope.permits(app),
           domain.matchesAnySubdomain(of: hostname) {
          return .allow(.permittedByKey(filterKey.id))
        }

      case .skeleton(scope: let singleScope):
        if AppScope.single(singleScope).permits(app) {
          return .allow(.permittedByKey(filterKey.id))
        }

      case .domainRegex(pattern: let pattern, scope: let scope):
        if flow.hostname?.matchesRegex(pattern.regex) == true,
           scope.permits(app) {
          return .allow(.permittedByKey(filterKey.id))
        }

      case .ipAddress(ipAddress: let ip, scope: let scope):
        if let ipAddress = flow.ipAddress,
           ipAddress == ip.string,
           scope.permits(app) {
          return .allow(.permittedByKey(filterKey.id))
        }

      case .path(path: let path, scope: let scope):
        if let url = flow.url,
           path.matches(url: url),
           scope.permits(app) {
          return .allow(.permittedByKey(filterKey.id))
        }
      }
    }

    // no need to wait for more flow data if we already have the url
    if flow.url != nil || !canDefer {
      return .block(.defaultNotAllowed)
    }

    return nil
  }

  private func activeSuspension(for userId: uid_t, permits app: AppDescriptor) -> Bool {
    guard let suspension = state.suspensions[userId], suspension.isActive else {
      return false
    }
    return suspension.scope.permits(app)
  }

  private func logged(_ decision: FilterDecision.FromFlow, from flow: FilterFlow) -> FilterDecision
    .FromFlow {
    #if DEBUG
      if getuid() < 500 { // prevent logging during tests
        switch decision {
        case .block(let reason):
          os_log(
            "[G•] filter decision: BLOCK %{public}@, reason: %{public}@",
            flow.shortDescription,
            "\(reason)"
          )
        case .allow(let reason):
          os_log(
            "[G•] filter decision: ALLOW %{public}@, reason: %{public}@",
            flow.shortDescription,
            "\(reason)"
          )
        }
      }
    #endif
    return decision
  }
}

private func bytesToString(_ bytes: Data) -> String {
  var str = ""
  bytes.forEach { byte in
    switch byte {
    // ascii characters possible in hostname
    case 45 ... 57, 61, 63, 65 ... 90, 95, 97 ... 122:
      str += String(Character(UnicodeScalar(byte)))
    default:
      str += "•"
    }
  }
  return str
}
