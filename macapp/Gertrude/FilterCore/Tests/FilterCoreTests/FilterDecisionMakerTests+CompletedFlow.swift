import Foundation
import Shared
import SharedCore

@testable import FilterCore

class FilterDecisionMakerCompletedFlowTests: FilterDecisionMakerTestCase {

  func testDomainAllowances() {
    let cases: [(keyDomain: String, flowHostname: String, verdict: NetworkDecisionVerdict)] = [
      (keyDomain: "safe.com", flowHostname: "Safe.com", verdict: .allow),
      (keyDomain: "safe.com", flowHostname: "safe.com", verdict: .allow),
      (keyDomain: "safe.com", flowHostname: "www.safe.com", verdict: .allow),
      (keyDomain: "www.safe.com", flowHostname: "safe.com", verdict: .allow),
      (keyDomain: "safe.com", flowHostname: "unsafe.com", verdict: .block),
      (keyDomain: "safe.com", flowHostname: "bad.safe.com", verdict: .block),
      (keyDomain: "safe.com", flowHostname: "safe.com.evil", verdict: .block),
    ]
    for (domain, hostname, verdict) in cases {
      let id = setOnlyKey(.domain(domain: .init(domain)!, scope: .unrestricted))
      let decision = maker.make(fromCompletedFlow: .test(hostname: hostname))
      if verdict == .allow {
        assertDecision(decision, .allow, .domainAllowed, id)
      } else {
        assertDecision(decision, .block, .defaultNotAllowed)
      }
    }
  }

  func testAnySubdomainAllowances() {
    let cases: [(keyDomain: String, flowHostname: String, verdict: NetworkDecisionVerdict)] = [
      (keyDomain: "safe.com", flowHostname: "safe.com", verdict: .allow),
      (keyDomain: "safe.com", flowHostname: "foo.safe.com", verdict: .allow),
      (keyDomain: "safe.com", flowHostname: "cdn.safe.com", verdict: .allow),
      (keyDomain: "www.safe.com", flowHostname: "safe.com", verdict: .allow),
      (keyDomain: "safe.com", flowHostname: "unsafe.com", verdict: .block),
    ]
    for (domain, hostname, verdict) in cases {
      let id = setOnlyKey(.anySubdomain(domain: .init(domain)!, scope: .unrestricted))
      let decision = maker.make(fromCompletedFlow: .test(hostname: hostname))
      if verdict == .allow {
        assertDecision(decision, .allow, .domainAllowed, id)
      } else {
        assertDecision(decision, .block, .defaultNotAllowed)
      }
    }
  }

  func testIpAddressAllowances() {
    let cases: [(keyIp: String, flowIp: String?, verdict: NetworkDecisionVerdict)] = [
      (keyIp: "1.2.3.4", flowIp: "1.2.3.4", verdict: .allow),
      (keyIp: "9.9.9.9", flowIp: "9.9.9.9", verdict: .allow),
      (keyIp: "1.2.3.4", flowIp: "1.2.3.999", verdict: .block),
      (keyIp: "1.2.3.4", flowIp: nil, verdict: .block),
      (keyIp: "2001:4998:58:204::2000", flowIp: "2001:4998:58:204::2000", verdict: .allow),
    ]
    for (keyIp, flowIp, verdict) in cases {
      let id = setOnlyKey(.ipAddress(ipAddress: .init(keyIp)!, scope: .unrestricted))
      let decision = maker.make(fromCompletedFlow: .test(ipAddress: flowIp))
      if verdict == .allow {
        assertDecision(decision, .allow, .ipAllowed, id)
      } else {
        assertDecision(decision, .block, .defaultNotAllowed)
      }
    }
  }

  func testPathKeys() {
    let cases: [(keyPath: String, flowUrl: String?, verdict: NetworkDecisionVerdict)] = [
      (keyPath: "github.com/htc/*", flowUrl: "https://github.com/htc/monkey", verdict: .allow),
      (keyPath: "github.com/htc/*", flowUrl: "http://github.com/htc/monkey", verdict: .allow),
      (keyPath: "github.com/htc/*", flowUrl: "https://github.com/bad-repo/htc", verdict: .block),
      (
        keyPath: "github.com/htc/*/new",
        flowUrl: "https://github.com/htc/monkey/new",
        verdict: .allow
      ),
      (
        keyPath: "github.com/htc/*/new",
        flowUrl: "https://github.com/htc/monkey/new/bad",
        verdict: .block
      ),
    ]
    for (keyPath, flowUrl, verdict) in cases {
      let id = setOnlyKey(.path(path: .init(keyPath)!, scope: .unrestricted))
      let decision = maker.make(fromCompletedFlow: .test(url: flowUrl))
      if verdict == .allow {
        assertDecision(decision, .allow, .pathAllowed, id)
      } else {
        assertDecision(decision, .block, .defaultNotAllowed)
      }
    }
  }

  func testInteractionBetweenMultipleUserKeys() {
    let id1 = addKey(.domain(domain: .init("one.com")!, scope: .unrestricted), userId: 501)
    let id2 = addKey(.domain(domain: .init("two.com")!, scope: .unrestricted), userId: 502)

    // user 1
    var decision = maker.make(fromCompletedFlow: .test(hostname: "one.com", userId: 501))
    assertDecision(decision, .allow, .domainAllowed, id1)
    decision = maker.make(fromCompletedFlow: .test(hostname: "two.com", userId: 501))
    assertDecision(decision, .block, .defaultNotAllowed)

    // user 2
    decision = maker.make(fromCompletedFlow: .test(hostname: "one.com", userId: 502))
    assertDecision(decision, .block, .defaultNotAllowed)
    decision = maker.make(fromCompletedFlow: .test(hostname: "two.com", userId: 502))
    assertDecision(decision, .allow, .domainAllowed, id2)
  }

  func testWeNolongerAllowIpAddressesAuthedByPriorHostnameAllowance() {
    let id = setOnlyKey(.domain(domain: "safe.com", scope: .unrestricted))
    let flow = FilterFlow.test(ipAddress: "1.2.3.4", hostname: "safe.com")
    let decision1 = maker.make(fromCompletedFlow: flow)
    assertDecision(decision1, .allow, .domainAllowed, id)

    // same ip address, unknown hostname
    let flow2 = FilterFlow.test(ipAddress: "1.2.3.4", hostname: nil)
    let decision2 = maker.make(fromCompletedFlow: flow2)
    assertDecision(decision2, .block, .defaultNotAllowed)

    // same ip address, different hostname
    let flow3 = FilterFlow.test(ipAddress: "1.2.3.4", hostname: "bad.com")
    let decision3 = maker.make(fromCompletedFlow: flow3)
    assertDecision(decision3, .block, .defaultNotAllowed)
  }

  func testUdpRequestFromUnrestrictedAppAllowed() {
    let id = setOnlyKey(.skeleton(scope: .bundleId("com.skype")))
    let unrestrictedAppFlow = FilterFlow.test(
      hostname: "foo.com",
      bundleId: "com.skype",
      port: .other(333),
      ipProtocol: .udp(Int32(IPPROTO_UDP))
    )
    let decision = maker.make(fromCompletedFlow: unrestrictedAppFlow)
    assertDecision(decision, .allow, .appUnrestricted, id)

    // but some other app is still blocked from making same request
    let otherAppFlow = FilterFlow.test(
      hostname: "foo.com",
      bundleId: "com.acme.widget",
      port: .other(333),
      ipProtocol: .udp(Int32(IPPROTO_UDP))
    )
    let otherAppDecision = maker.make(fromCompletedFlow: otherAppFlow)
    assertDecision(otherAppDecision, .block, .defaultNotAllowed)
  }

  func testFlowAllowedImmediatelyWhenFilterCompletelySuspended() {
    addSuspension(.unrestricted)
    let decision = maker.make(fromCompletedFlow: .test(hostname: "radsite.com"))
    assertDecision(decision, .allow, .filterSuspended)
  }

  func testWebBrowsersOnlySuspensionAllowsBrowserRequest() {
    addSuspension(.webBrowsers)
    let decision = maker.make(fromCompletedFlow: .test(hostname: "radsite.com"))
    assertDecision(decision, .allow, .filterSuspended)
  }

  func testWebBrowsersOnlySuspensionDoesNotAllowWrongUser() {
    addSuspension(.webBrowsers, userId: 502)
    let decision = maker.make(fromCompletedFlow: .test(hostname: "radsite.com"))
    assertDecision(decision, .block, .defaultNotAllowed)
  }

  func testWebBrowsersSuspensionDoesNotAllowNonWebBrowserRequest() {
    addSuspension(.webBrowsers)
    let flow = FilterFlow.test(hostname: "radsite.com", bundleId: "com.xcode")
    let decision = maker.make(fromCompletedFlow: flow)
    assertDecision(decision, .block, .defaultNotAllowed)
  }

  func testIdentifiedAppSlugSuspensionAllowsRequestFromApp() {
    addSuspension(.single(.identifiedAppSlug("chrome")))
    let decision = maker.make(fromCompletedFlow: .test(hostname: "radsite.com"))
    assertDecision(decision, .allow, .filterSuspended)
  }

  func testIdentifiedAppSlugSuspensionDoesNotAllowNonMatchingRequest() {
    addSuspension(.single(.identifiedAppSlug("chrome")))
    let flow = FilterFlow.test(hostname: "radsite.com", bundleId: "com.xcode")
    let decision = maker.make(fromCompletedFlow: flow)
    assertDecision(decision, .block, .defaultNotAllowed)
  }

  func testBundleIdSuspensionAllowsRequestFromApp() {
    addSuspension(.single(.bundleId("com.chrome")))
    let decision = maker.make(fromCompletedFlow: .test(hostname: "radsite.com"))
    assertDecision(decision, .allow, .filterSuspended)
  }

  func testBundleIdSuspensionDoesNotAllowNonMatchingRequest() {
    addSuspension(.single(.bundleId("com.chrome")))
    let flow = FilterFlow.test(hostname: "radsite.com", bundleId: "com.xcode")
    let decision = maker.make(fromCompletedFlow: flow)
    assertDecision(decision, .block, .defaultNotAllowed)
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
      var id = setOnlyKey(.domainRegex(pattern: pattern, scope: .unrestricted))
      let unrestricted = maker.make(fromCompletedFlow: .test(
        hostname: hostname,
        bundleId: "com.\(Int.random(in: 100_000 ... 999_999))"
      ))
      assertDecision(unrestricted, .allow, .domainAllowed, id)

      // when scope = .webBrowsers, only allows web browsers
      id = setOnlyKey(.domainRegex(pattern: pattern, scope: .webBrowsers))
      let browser = maker.make(fromCompletedFlow: .test(hostname: hostname, bundleId: "com.chrome"))
      assertDecision(browser, .allow, .domainAllowed, id)
      let xcode = maker.make(fromCompletedFlow: .test(hostname: hostname, bundleId: "com.xcode"))
      assertDecision(xcode, .block, .defaultNotAllowed)

      // when scope = .single(.identifiedAppSlug), only allows matching app
      id = setOnlyKey(.domainRegex(pattern: pattern, scope: .single(.identifiedAppSlug("chrome"))))
      let appSlug = maker.make(fromCompletedFlow: .test(hostname: hostname, bundleId: "com.chrome"))
      assertDecision(appSlug, .allow, .domainAllowed, id)
      let slack = maker.make(fromCompletedFlow: .test(hostname: hostname, bundleId: "com.slack"))
      assertDecision(slack, .block, .defaultNotAllowed)

      // when scope = .single(.bundleId), only allows matching app
      id = setOnlyKey(.domainRegex(pattern: pattern, scope: .single(.bundleId("com.chrome"))))
      let bundle = maker.make(fromCompletedFlow: .test(hostname: hostname, bundleId: "com.chrome"))
      assertDecision(bundle, .allow, .domainAllowed, id)
      let skype = maker.make(fromCompletedFlow: .test(hostname: hostname, bundleId: "com.skype"))
      assertDecision(skype, .block, .defaultNotAllowed)
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
      setOnlyKey(.domainRegex(pattern: .init(pattern)!, scope: .unrestricted))
      let decision = maker.make(fromCompletedFlow: .test(hostname: hostname))
      assertDecision(decision, .block, .defaultNotAllowed)
    }
  }

  func testUnknownIpAddressAndHostNamedBlocked() {
    let flow = FilterFlow.test(ipAddress: "5.5.5.5", hostname: "unknown.com")
    let decision = maker.make(fromCompletedFlow: flow)
    assertDecision(decision, .block, .defaultNotAllowed)
  }

  func testFlowAllowedWhenFilterCompletelySuspended() {
    maker.suspensions.set(.init(scope: .unrestricted, duration: 1000), userId: 501)
    let decision = maker.make(fromCompletedFlow: .init(hostname: "radsite.com", userId: 501))
    assertDecision(decision, .allow, .filterSuspended)
  }

  func testFlowBlockedWhenSuspensionExpired() {
    maker.suspensions.set(.init(scope: .unrestricted, duration: -1000), userId: 501)
    let decision = maker.make(fromCompletedFlow: .init(hostname: "radsite.com", userId: 501))
    assertDecision(decision, .block, .defaultNotAllowed)
  }

  func testSupportingFileExtensionsNotPermitted() {
    setOnlyKey(.domain(domain: "radsite.com", scope: .unrestricted))
    let allowed = ["css", "js", "woff"]
    let notAllowed = ["mp3", "m4v", "jpg"]

    for allowedExt in allowed {
      let flow = FilterFlow.test(url: "https://othersite.com/foo.\(allowedExt)")
      let decision = maker.make(fromCompletedFlow: flow)
      assertDecision(decision, .block, .defaultNotAllowed)
    }

    for allowedExt in allowed {
      let flow = FilterFlow.test(url: "https://othersite.com/foo.\(allowedExt)?lol=rofl&jim=jam")
      let decision = maker.make(fromCompletedFlow: flow)
      assertDecision(decision, .block, .defaultNotAllowed)
    }

    for notAllowedExt in notAllowed {
      let flow = FilterFlow.test(url: "https://othersite.com/foo.\(notAllowedExt)")
      let decision = maker.make(fromCompletedFlow: flow)
      assertDecision(decision, .block, .defaultNotAllowed)
    }

    for notAllowedExt in notAllowed {
      let flow = FilterFlow.test(url: "https://othersite.com/foo.\(notAllowedExt)?whoops=.css")
      let decision = maker.make(fromCompletedFlow: flow)
      assertDecision(decision, .block, .defaultNotAllowed)
    }
  }
}
