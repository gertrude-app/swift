import Shared
import SharedCore
import XCTest

@testable import FilterCore

class FilterDecisionMakerNewFlowTests: FilterDecisionMakerTestCase {
  // the failure of these requests caused the SystemUIServer daemon to repeatedly crash
  // causing the menu bar to hide/delete/flash, do crazy stuff every few seconds
  func testSystemUiServerAllowedToTalkToPrivateIps() throws {
    let privateIps = [
      "10.0.1.1",
      "192.168.3.5",
      "100.64.3.3",
      "192.0.0.3",
      "172.16.0.0",
      "172.28.111.111",
      "172.31.255.255",
    ]
    for ip in privateIps {
      let flow = FilterFlow(ipAddress: ip, bundleId: ".com.apple.systemuiserver")
      let decision = maker.make(fromFlow: flow)
      assertDecision(decision, .allow, .systemUiServerInternal)
    }
  }

  func testDecisionIsNilWhenNoKeyAllowsAndUrlIsMissing() {
    let flow = FilterFlow.test(url: nil, hostname: "unknown.com", bundleId: "com.foo.bar")
    let decision = maker.make(fromFlow: flow)
    XCTAssertNil(decision)
  }

  func testDecisionIsBlockWhenNoKeyAllowsAndUrlIsPresent() {
    let flow = FilterFlow.test(
      url: "https://unknown.com/foo",
      hostname: "unknown.com",
      bundleId: "com.foo.bar"
    )
    let decision = maker.make(fromFlow: flow)
    assertDecision(decision, .block, .defaultNotAllowed)
  }

  func testFlowAllowedForAppWithUnrestrictedScope() {
    setOnlyKey(.skeleton(scope: .bundleId("com.foo")))
    let flow = FilterFlow.test(ipAddress: "4.4.4.4", hostname: "abc123.com", bundleId: "com.foo")
    let decision = maker.make(fromFlow: flow)
    assertDecision(decision, .allow, .appUnrestricted)
  }

  func testUdpFlowAllowedForAppWithUnrestrictedScope() {
    setOnlyKey(.skeleton(scope: .bundleId("com.foo")))
    let flow = FilterFlow.test(
      ipAddress: "4.4.4.4",
      hostname: "abc123.com",
      bundleId: "com.foo",
      port: .other(333),
      ipProtocol: .udp(Int32(IPPROTO_UDP))
    )
    let decision = maker.make(fromFlow: flow)
    assertDecision(decision, .allow, .appUnrestricted)
  }

  func testAllKeysChecked() {
    addKey(.domain(domain: "foo.com", scope: .webBrowsers))
    let id = addKey(.domain(domain: "bar.com", scope: .webBrowsers)) // <-- second key
    let decision = maker.make(fromFlow: .test(hostname: "bar.com"))
    assertDecision(decision, .allow, .domainAllowed, id)
  }

  func testFlowAllowedForAppWithUnrestrictedScopeNoHostname() {
    setOnlyKey(.skeleton(scope: .identifiedAppSlug("chrome")))
    let flow = FilterFlow.test(ipAddress: "4.4.4.4", hostname: nil)
    let decision = maker.make(fromFlow: flow)
    assertDecision(decision, .allow, .appUnrestricted)
  }

  func testDnsUdpRequestsAlwaysAllowed() {
    let flow = FilterFlow(port: .dns(53), ipProtocol: .udp(Int32(IPPROTO_UDP)))
    let decision = maker.make(fromFlow: flow)
    assertDecision(decision, .allow, .dns)
  }

  func testFlowRejectedWhenNoKeys() {
    maker.userKeys = [:]
    let decision = maker.make(fromFlow: .test())
    assertDecision(decision, .block, .missingKeychains)
  }

  func testDoesNotBlockOwnRequests() {
    let cases: [(
      ip: String?,
      hostname: String?,
      url: String?,
      bundleId: String,
      verdict: NetworkDecisionVerdict
    )] =
      [
        (
          ip: nil,
          hostname: nil,
          url: nil,
          bundleId: "com.netrivet.gertrude.app",
          verdict: .allow
        ),
        (
          ip: nil,
          hostname: nil,
          url: nil,
          bundleId: "WFN83LM943.com.netrivet.gertrude.app",
          verdict: .allow
        ),
        (
          ip: "1.2.3.4",
          hostname: "foo.com",
          url: "https://foo.com/bar",
          bundleId: "WFN83LM943.com.netrivet.gertrude.app",
          verdict: .allow
        ),
        (
          ip: nil,
          hostname: nil,
          url: nil,
          bundleId: "gertrude.app.imposter",
          verdict: .block
        ),
      ]
    for (ip, hostname, url, bundleId, verdict) in cases {
      let flow = FilterFlow.test(url: url, ipAddress: ip, hostname: hostname, bundleId: bundleId)
      let decision = maker.make(fromFlow: flow)
      if verdict == .allow {
        assertDecision(decision, .allow, .fromGertrudeApp)
      } else {
        XCTAssertNil(decision)
      }
    }
  }

  func testOwnRequestStillAllowedWhenKeychainsMissing() {
    maker.userKeys = [:]
    let decision = maker.make(fromFlow: .test(bundleId: "com.netrivet.gertrude.app"))
    assertDecision(decision, .allow, .fromGertrudeApp)
  }
}
