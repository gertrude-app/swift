import Core
import Shared
import XCTest
import XExpect

@testable import Filter

final class CompletedFlowDecisionTests: XCTestCase {
  func testDomainAllowances() {
    assertDecisions([
      (.domain(keyDomain: "safe.com", flowHostname: "Safe.com"), .allow),
      (.domain(keyDomain: "safe.com", flowHostname: "safe.com"), .allow),
      (.domain(keyDomain: "safe.com", flowHostname: "www.safe.com"), .allow),
      (.domain(keyDomain: "www.safe.com", flowHostname: "safe.com"), .allow),
      (.domain(keyDomain: "safe.com", flowHostname: "unsafe.com"), .block),
      (.domain(keyDomain: "safe.com", flowHostname: "bad.safe.com"), .block),
      (.domain(keyDomain: "safe.com", flowHostname: "safe.com.evil"), .block),
    ])
  }

  func testAnySubdomainAllowances() {
    assertDecisions([
      (.subdomain(keyDomain: "safe.com", flowHostname: "safe.com"), .allow),
      (.subdomain(keyDomain: "safe.com", flowHostname: "foo.safe.com"), .allow),
      (.subdomain(keyDomain: "safe.com", flowHostname: "cdn.safe.com"), .allow),
      (.subdomain(keyDomain: "www.safe.com", flowHostname: "safe.com"), .allow),
      (.subdomain(keyDomain: "safe.com", flowHostname: "unsafe.com"), .block),
    ])
  }

  func testIpAddressAllowances() {
    assertDecisions([
      (.ip(keyIp: "1.2.3.4", flowIp: "1.2.3.4"), .allow),
      (.ip(keyIp: "9.9.9.9", flowIp: "9.9.9.9"), .allow),
      (.ip(keyIp: "1.2.3.4", flowIp: "1.2.3.999"), .block),
      (.ip(keyIp: "1.2.3.4", flowIp: nil), .block),
      (.ip(keyIp: "2001:4998:58:204::2000", flowIp: "2001:4998:58:204::2000"), .allow),
    ])
  }

  func testPathKeys() {
    assertDecisions([
      (.path(key: "github.com/htc/*", flowUrl: "https://github.com/htc/monkey"), .allow),
      (.path(key: "github.com/htc/*", flowUrl: "http://github.com/htc/monkey"), .allow),
      (.path(key: "github.com/htc/*", flowUrl: "https://github.com/bad-repo/htc"), .block),
      (.path(key: "github.com/htc/*/new", flowUrl: "https://github.com/htc/foo/new"), .allow),
      (.path(key: "github.com/htc/*/new", flowUrl: "https://github.com/htc/foo/new/bad"), .block),
    ])
  }

  func testInteractionBetweenMultipleUserKeys() {
    let key1 = FilterKey(key: .domain(domain: "one.com", scope: .unrestricted))
    let key2 = FilterKey(key: .domain(domain: "two.com", scope: .unrestricted))

    // // user 1
    var filter = TestFilter.scenario(userKeys: [502: [key1], 503: [key2]])
    let flow1 = FilterFlow.test(hostname: "one.com", userId: 502)
    expect(filter.completedDecision(flow1)).toEqual(.allow(.permittedByKey(key1.id)))
    let flow2 = FilterFlow.test(hostname: "two.com", userId: 502)
    expect(filter.completedDecision(flow2)).toEqual(.block(.defaultNotAllowed))

    // user 2
    filter = TestFilter.scenario(userKeys: [502: [key1], 503: [key2]])
    let flow3 = FilterFlow.test(hostname: "one.com", userId: 503)
    expect(filter.completedDecision(flow3)).toEqual(.block(.defaultNotAllowed))
    let flow4 = FilterFlow.test(hostname: "two.com", userId: 503)
    expect(filter.completedDecision(flow4)).toEqual(.allow(.permittedByKey(key2.id)))
  }

  func testWeNolongerAllowIpAddressesAuthedByPriorHostnameAllowance() {
    let key = FilterKey(key: .domain(domain: "safe.com", scope: .unrestricted))
    let flow = FilterFlow.test(ipAddress: "1.2.3.4", hostname: "safe.com")
    let filter = TestFilter.scenario(userKeys: [502: [key]])
    let decision1 = filter.completedDecision(flow)
    expect(decision1).toEqual(.allow(.permittedByKey(key.id)))

    // same ip address, unknown hostname
    let flow2 = FilterFlow.test(ipAddress: "1.2.3.4", hostname: nil)
    let decision2 = filter.completedDecision(flow2)
    expect(decision2).toEqual(.block(.defaultNotAllowed))

    // same ip address, different hostname
    let flow3 = FilterFlow.test(ipAddress: "1.2.3.4", hostname: "bad.com")
    let decision3 = filter.completedDecision(flow3)
    expect(decision3).toEqual(.block(.defaultNotAllowed))
  }

  func testUdpRequestFromUnrestrictedAppAllowed() {
    let key = FilterKey(key: .skeleton(scope: .bundleId("com.skype")))
    let filter = TestFilter.scenario(userKeys: [502: [key]])
    let unrestrictedAppFlow = FilterFlow.test(
      hostname: "foo.com",
      bundleId: "com.skype",
      port: .other(333),
      ipProtocol: .udp(Int32(IPPROTO_UDP))
    )
    let decision = filter.completedDecision(unrestrictedAppFlow)
    expect(decision).toEqual(.allow(.permittedByKey(key.id)))

    // but some other app is still blocked from making same request
    let otherAppFlow = FilterFlow.test(
      hostname: "foo.com",
      bundleId: "com.acme.widget",
      port: .other(333),
      ipProtocol: .udp(Int32(IPPROTO_UDP))
    )
    let otherAppDecision = filter.completedDecision(otherAppFlow)
    expect(otherAppDecision).toEqual(.block(.defaultNotAllowed))
  }

  func testFlowAllowedImmediatelyWhenFilterCompletelySuspended() {
    let filter = TestFilter
      .scenario(suspensions: [502: .init(scope: .unrestricted, duration: 1000)])
    let decision = filter.completedDecision(.test(hostname: "radsite.com"))
    expect(decision).toEqual(.allow(.filterSuspended))
  }

  func testWebBrowsersOnlySuspensionAllowsBrowserRequest() {
    let filter = TestFilter
      .scenario(suspensions: [502: .init(scope: .webBrowsers, duration: 1000)])
    let decision = filter.completedDecision(.test(hostname: "radsite.com"))
    expect(decision).toEqual(.allow(.filterSuspended))
  }

  func testWebBrowsersOnlySuspensionDoesNotAllowWrongUser() {
    let filter = TestFilter.scenario(suspensions: [504: .init(scope: .webBrowsers, duration: 1000)])
    let decision = filter.completedDecision(.test(hostname: "radsite.com", userId: 502))
    expect(decision).toEqual(.block(.defaultNotAllowed))
  }

  func testWebBrowsersSuspensionDoesNotAllowNonWebBrowserRequest() {
    let filter = TestFilter.scenario(suspensions: [502: .init(scope: .webBrowsers, duration: 1000)])
    let decision = filter.completedDecision(.test(hostname: "radsite.com", bundleId: "com.xcode"))
    expect(decision).toEqual(.block(.defaultNotAllowed))
  }

  func testIdentifiedAppSlugSuspensionAllowsRequestFromApp() {
    let filter = TestFilter.scenario(suspensions: [502: .init(
      scope: .single(.identifiedAppSlug("chrome")),
      duration: 1000
    )])
    let decision = filter.completedDecision(.test(hostname: "radsite.com", bundleId: "com.chrome"))
    expect(decision).toEqual(.allow(.filterSuspended))
  }

  func testIdentifiedAppSlugSuspensionDoesNotAllowNonMatchingRequest() {
    let filter = TestFilter.scenario(suspensions: [502: .init(
      scope: .single(.identifiedAppSlug("chrome")),
      duration: 1000
    )])
    let decision = filter.completedDecision(.test(hostname: "radsite.com", bundleId: "com.xcode"))
    expect(decision).toEqual(.block(.defaultNotAllowed))
  }

  func testBundleIdSuspensionAllowsRequestFromApp() {
    let filter = TestFilter.scenario(suspensions: [502: .init(
      scope: .single(.bundleId("com.chrome")),
      duration: 1000
    )])
    let decision = filter.completedDecision(.test(hostname: "radsite.com", bundleId: "com.chrome"))
    expect(decision).toEqual(.allow(.filterSuspended))
  }

  func testBundleIdSuspensionDoesNotAllowNonMatchingRequest() {
    let filter = TestFilter.scenario(suspensions: [502: .init(
      scope: .single(.bundleId("com.chrome")),
      duration: 1000
    )])
    let decision = filter.completedDecision(.test(hostname: "radsite.com", bundleId: "com.xcode"))
    expect(decision).toEqual(.block(.defaultNotAllowed))
  }

  func testDomainRegexKeyAllowances() {
    let cases = [
      ("a-*-b.foo.com", "a-3-b.foo.com"),
      ("a-*-b.foo.com", "a-reallylongstuffhere-b.foo.com"),
      ("*--preview.netlify.app", "foobar--preview.netlify.app"),
      ("*--preview.netlify.app", "--preview.netlify.app"),
      ("preview--*.netlify.app", "preview--33.netlify.app"),
      ("preview--*.netlify.app", "preview--.netlify.app"),
      ("deploy-preview-*--site.netlify.app", "deploy-preview-36--site.netlify.app"),
      ("foo.lol.*", "foo.lol.biz"),
    ]
    for (patternStr, hostname) in cases {
      let pattern = Key.DomainRegexPattern(patternStr)!
      // ALLOWS any matching hostname when scope = .unrestricted
      var key = FilterKey(key: .domainRegex(pattern: pattern, scope: .unrestricted))
      let flow = FilterFlow.test(hostname: hostname, bundleId: "com.\(UUID())")
      var filter = TestFilter.scenario(userKeys: [502: [key]])
      expect(filter.completedDecision(flow)).toEqual(.allow(.permittedByKey(key.id)))

      // when scope = .webBrowsers, only allows web browsers
      key = FilterKey(key: .domainRegex(pattern: pattern, scope: .webBrowsers))
      filter = TestFilter.scenario(userKeys: [502: [key]])
      let browserFlow = FilterFlow.test(hostname: hostname, bundleId: "com.chrome")
      expect(filter.completedDecision(browserFlow)).toEqual(.allow(.permittedByKey(key.id)))
      let xcodeFlow = FilterFlow.test(hostname: hostname, bundleId: "com.xcode")
      expect(filter.completedDecision(xcodeFlow)).toEqual(.block(.defaultNotAllowed))

      // when scope = .single(.identifiedAppSlug), only allows matching app
      key = .init(key: .domainRegex(pattern: pattern, scope: .single(.identifiedAppSlug("chrome"))))
      filter = TestFilter.scenario(userKeys: [502: [key]])
      let appSlugFlow = FilterFlow.test(hostname: hostname, bundleId: "com.chrome")
      expect(filter.completedDecision(appSlugFlow)).toEqual(.allow(.permittedByKey(key.id)))
      let slackFlow = FilterFlow.test(hostname: hostname, bundleId: "com.slack")
      expect(filter.completedDecision(slackFlow)).toEqual(.block(.defaultNotAllowed))

      // when scope = .single(.bundleId), only allows matching app
      key = .init(key: .domainRegex(pattern: pattern, scope: .single(.bundleId("com.chrome"))))
      filter = TestFilter.scenario(userKeys: [502: [key]])
      let bundleFlow = FilterFlow.test(hostname: hostname, bundleId: "com.chrome")
      expect(filter.completedDecision(bundleFlow)).toEqual(.allow(.permittedByKey(key.id)))
      let skypeFlow = FilterFlow.test(hostname: hostname, bundleId: "com.skype")
      expect(filter.completedDecision(skypeFlow)).toEqual(.block(.defaultNotAllowed))
    }
  }

  func testDomainRegexKeyNonMatches() {
    let cases = [
      ("a-*-b.foo.com", "a-3-b.BAR.com"),
      ("a-*-b.foo.com", "missingpreface-b.foo.com"),
      ("*--preview.netlify.app", "foobar--production.netlify.app"),
      ("*--preview.netlify.app", "--production.netlify.app"),
      ("preview--*.netlify.app", "prod--33.netlify.app"),
      ("preview--*.netlify.app", "prod--.netlify.app"),
      ("deploy-preview-*--site.netlify.app", "deploy-preview-36--other.netlify.app"),
      ("foo.lol.*", "bar.lol"),
    ]
    for (pattern, hostname) in cases {
      let key = FilterKey(key: .domainRegex(pattern: .init(pattern)!, scope: .unrestricted))
      let filter = TestFilter.scenario(userKeys: [502: [key]])
      let decision = filter.completedDecision(.test(hostname: hostname))
      expect(decision).toEqual(.block(.defaultNotAllowed))
    }
  }

  func testUnknownIpAddressAndHostNamedBlocked() {
    let flow = FilterFlow.test(ipAddress: "5.5.5.5", hostname: "unknown.com")
    let filter = TestFilter.scenario()
    let decision = filter.completedDecision(flow)
    expect(decision).toEqual(.block(.defaultNotAllowed))
  }
}

extension NetworkFilter {
  func completedDecision(_ flow: FilterFlow) -> FilterDecision.FromFlow {
    completedFlowDecision(flow, readBytes: .init())
  }
}

extension CompletedFlowDecisionTests {
  enum TestCase {
    enum Input {
      case domain(keyDomain: String, flowHostname: String)
      case subdomain(keyDomain: String, flowHostname: String)
      case ip(keyIp: String, flowIp: String?)
      case path(key: String, flowUrl: String)
    }

    enum Decision {
      case allow
      case block
    }
  }

  func assertDecisions(_ cases: [(TestCase.Input, TestCase.Decision)]) {
    for (input, decision) in cases {
      let key: FilterKey
      let flow: FilterFlow
      switch input {
      case .domain(let keyDomain, let flowHostname):
        key = FilterKey(key: .domain(domain: .init(keyDomain)!, scope: .unrestricted))
        flow = FilterFlow.test(hostname: flowHostname)
      case .subdomain(let keyDomain, let flowHostname):
        key = FilterKey(key: .anySubdomain(domain: .init(keyDomain)!, scope: .unrestricted))
        flow = FilterFlow.test(hostname: flowHostname)
      case .ip(let keyIp, let flowIp):
        key = FilterKey(key: .ipAddress(ipAddress: .init(keyIp)!, scope: .unrestricted))
        flow = FilterFlow.test(ipAddress: flowIp)
      case .path(let keyPath, let flowUrl):
        key = FilterKey(key: .path(path: .init(keyPath)!, scope: .unrestricted))
        flow = FilterFlow.test(url: flowUrl)
      }
      let filter = TestFilter.scenario(userKeys: [502: [key]])
      let flowDecision = decision == .allow ? FilterDecision.FromFlow
        .allow(.permittedByKey(key.id)) : .block(.defaultNotAllowed)
      expect(filter.completedFlowDecision(flow, readBytes: .init())).toEqual(flowDecision)
    }
  }
}
