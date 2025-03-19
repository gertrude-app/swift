import Core
import Foundation
import Gertie
import os.log

public extension NetworkFilter {
  func newFlowDecision(
    _ flow: FilterFlow,
    auditToken: Data? = nil
  ) -> FilterDecision.FromFlow? {
    #if DEBUG
      if let mock = self.__TEST_MOCK_FLOW_DECISION { return mock }
    #endif
    return self.flowDecision(flow, auditToken: auditToken, canDefer: true)
  }

  func completedFlowDecision(
    _ flow: inout FilterFlow,
    readBytes: Data,
    auditToken: Data? = nil
  ) -> FilterDecision.FromFlow {
    #if DEBUG
      if case .some(.some(let mock)) = self.__TEST_MOCK_FLOW_DECISION { return mock }
    #endif
    if flow.url == nil {
      flow.parseOutboundData(byteString: bytesToAscii(readBytes))
    }
    return self.flowDecision(flow, auditToken: auditToken, canDefer: false) ??
      .block(.defaultNotAllowed)
  }

  private func flowDecision(
    _ flow: FilterFlow,
    auditToken: Data?,
    canDefer: Bool
  ) -> FilterDecision.FromFlow? {

    if flow.isDnsRequest {
      return .allow(.dnsRequest)
    }

    if flow.isSystemUiServerInternal {
      // special allowance for system app that causes menubar flakiness if blocked
      return .allow(.systemUiServerInternal)
    }

    let fromGertrude = flow.isFromGertrude
    if fromGertrude, flow.hostname?.contains(".xpc.") != true {
      return .allow(.fromGertrudeApp)
    }

    guard let userId = flow.userId ?? security.userIdFromAuditToken(auditToken) else {
      return .block(.missingUserId)
    }

    if fromGertrude, flow.hostname == XPC.URLMessage.alive(userId).hostname {
      return .block(.urlMessage(.alive(userId)))
    }

    if self.state.macappsAliveUntil[userId] == nil,
       self.state.userKeychains[userId] != nil {
      return .block(.macappAWOL(userId))
    }

    let app = appDescriptor(for: flow.bundleId ?? "", auditToken: auditToken)
    if self.activeSuspension(for: userId, permits: app) {
      return .allow(.filterSuspended)
    }

    let keychains = self.state.userKeychains[userId] ?? []
    guard !keychains.isEmpty else {
      return .block(.noUserKeys)
    }

    for keychain in keychains {
      if keychain.schedule?.active(at: self.now, in: self.calendar) == false {
        continue
      }
      for ruleKey in keychain.keys {
        switch ruleKey.key {

        case .domain(domain: let domain, scope: let scope):
          if let hostname = flow.hostname, scope.permits(app),
             domain.matches(hostname: hostname) {
            return .allow(.permittedByKey(ruleKey.id))
          }

        case .anySubdomain(domain: let domain, scope: let scope):
          if let hostname = flow.hostname,
             scope.permits(app),
             domain.matchesAnySubdomain(of: hostname) {
            return .allow(.permittedByKey(ruleKey.id))
          }

        case .skeleton(scope: let singleScope):
          if AppScope.single(singleScope).permits(app) {
            return .allow(.permittedByKey(ruleKey.id))
          }

        case .domainRegex(pattern: let pattern, scope: let scope):
          if flow.hostname?.matchesRegex(pattern.regex) == true,
             scope.permits(app) {
            return .allow(.permittedByKey(ruleKey.id))
          }

        case .ipAddress(ipAddress: let ip, scope: let scope):
          if let ipAddress = flow.ipAddress,
             ipAddress == ip.string,
             scope.permits(app) {
            return .allow(.permittedByKey(ruleKey.id))
          }

        case .path(path: let path, scope: let scope):
          if let url = flow.url,
             path.matches(url: url),
             scope.permits(app) {
            return .allow(.permittedByKey(ruleKey.id))
          }
        }
      }
    }

    // no need to wait for more flow data if we already have the url
    if flow.url != nil || !canDefer {
      return .block(.defaultNotAllowed)
    }

    return nil
  }

  private func activeSuspension(
    for userId: uid_t,
    permits app: AppDescriptor
  ) -> Bool {
    guard let suspension = state.suspensions[userId], suspension.isActive else {
      return false
    }
    return suspension.scope.permits(app)
  }
}

public func bytesToAscii(_ bytes: Data) -> String {
  var str = ""
  for byte in bytes {
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
