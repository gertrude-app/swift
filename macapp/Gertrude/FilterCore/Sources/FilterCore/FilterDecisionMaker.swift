import Foundation
import Shared
import SharedCore

public final class FilterDecisionMaker {
  public var userKeys: [uid_t: [FilterKey]] = [:]
  public var suspensions = FilterSuspensions()
  public var appDescriptorFactory = AppDescriptorFactory()

  public func make(userId: uid_t?, exemptedUsers: Set<uid_t>?) -> FilterDecision? {
    guard let userId = userId else {
      return .init(verdict: .block, reason: .missingUserId)
    }

    if userId < 500 {
      return .init(verdict: .allow, reason: .systemUser)
    }

    if exemptedUsers?.contains(userId) == true {
      return .init(verdict: .allow, reason: .userIsExempt)
    }

    if let suspension = suspensions.get(userId: userId), suspension.scope == .unrestricted {
      return .init(verdict: .allow, reason: .filterSuspended)
    }

    return nil
  }

  public func make(fromCompletedFlow flow: FilterFlow) -> FilterDecision {
    make(fromFlow: flow, canDefer: false) ?? .init(
      verdict: .block,
      reason: .defaultNotAllowed,
      app: appDescriptorFactory.make(fromFlow: flow),
      filterFlow: flow
    )
  }

  public func make(fromFlow flow: FilterFlow, canDefer: Bool = true) -> FilterDecision? {
    let app = appDescriptorFactory.make(fromFlow: flow)
    if flow.isDnsRequest {
      return .init(verdict: .allow, reason: .dns, app: app, filterFlow: flow)
    }

    if flow.bundleId == ".com.apple.systemuiserver", flow.isPrivateNetwork {
      return .init(verdict: .allow, reason: .systemUiServerInternal, app: app, filterFlow: flow)
    }

    if flow.bundleId?.contains("com.netrivet.gertrude.app") == true {
      return .init(verdict: .allow, reason: .fromGertrudeApp, app: app, filterFlow: flow)
    }

    if let suspended = suspensionAllowance(flow, app) {
      return suspended
    }

    let keys = userKeys[flow.userId ?? 0] ?? []
    guard !keys.isEmpty else {
      return .init(verdict: .block, reason: .missingKeychains, app: app, filterFlow: flow)
    }

    for userKey in keys {
      // @OPTIMIZE: these could be re-ordered based on frequency of real-world use
      switch userKey.type {
      case .domain(domain: let domain, scope: let scope):
        if let hostname = flow.hostname,
           scope.permits(app),
           domain.matches(hostname: hostname) {
          return .init(
            verdict: .allow,
            reason: .domainAllowed,
            app: app,
            filterFlow: flow,
            responsibleKeyId: userKey.id
          )
        }
      case .anySubdomain(domain: let domain, scope: let scope):
        if let hostname = flow.hostname,
           scope.permits(app),
           domain.matchesAnySubdomain(of: hostname) {
          return .init(
            verdict: .allow,
            reason: .domainAllowed,
            app: app,
            filterFlow: flow,
            responsibleKeyId: userKey.id
          )
        }
      case .skeleton(scope: let singleScope):
        if AppScope.single(singleScope).permits(app) {
          return .init(
            verdict: .allow,
            reason: .appUnrestricted,
            app: app,
            filterFlow: flow,
            responsibleKeyId: userKey.id
          )
        }
      case .domainRegex(pattern: let pattern, scope: let scope):
        if flow.hostname?.matchesRegex(pattern.regex) == true,
           scope.permits(app) {
          return .init(
            verdict: .allow,
            reason: .domainAllowed,
            app: app,
            filterFlow: flow,
            responsibleKeyId: userKey.id
          )
        }
      case .ipAddress(ipAddress: let ip, scope: let scope):
        if let ipAddress = flow.ipAddress,
           ipAddress == ip.string,
           scope.permits(app) {
          return .init(
            verdict: .allow,
            reason: .ipAllowed,
            app: app,
            filterFlow: flow,
            responsibleKeyId: userKey.id
          )
        }
      case .path(path: let path, scope: let scope):
        if let url = flow.url,
           path.matches(url: url),
           scope.permits(app) {
          return .init(
            verdict: .allow,
            reason: .pathAllowed,
            app: app,
            filterFlow: flow,
            responsibleKeyId: userKey.id
          )
        }
      }
    }

    // no need to wait for more flow data if we already have the url
    if flow.url != nil || !canDefer {
      return .init(verdict: .block, reason: .defaultNotAllowed, app: app, filterFlow: flow)
    }

    return nil
  }

  private func suspensionAllowance(
    _ flow: FilterFlow,
    _ app: AppDescriptor
  ) -> FilterDecision? {
    guard let userId = flow.userId, let suspension = suspensions.get(userId: userId) else {
      return nil
    }
    return suspension.scope
      .permits(app)
      ? .init(verdict: .allow, reason: .filterSuspended, app: app, filterFlow: flow)
      : nil
  }

  public init() {}
}

// helpers

private func fileExt(from url: String) -> String? {
  guard let path = url.components(separatedBy: "/").last else {
    return nil
  }

  guard let withoutQuery = path.components(separatedBy: "?").first else {
    return nil
  }

  let split = withoutQuery.components(separatedBy: ".")
  guard split.count > 1 else {
    return nil
  }
  guard let ext = split.last else {
    return nil
  }

  return ext.count < 5 ? ".\(ext.lowercased())" : nil
}
