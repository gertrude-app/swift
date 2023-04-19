import Core
import Shared
import XCTest
import XExpect

@testable import Filter

final class NewFlowDecisionTests: XCTestCase {
  // the blocking of these requests caused the SystemUIServer daemon to repeatedly crash
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
      expect(TestFilter().newFlowDecision(flow)).toEqual(.allow(.systemUiServerInternal))
    }
  }

  func testDecisionIsNilWhenNoKeyAllowsAndUrlIsMissing() {
    let flow = FilterFlow.test(url: nil, hostname: "unknown.com", bundleId: "com.foo.bar")
    expect(TestFilter.scenario().newFlowDecision(flow)).toBeNil()
  }

  func testDecisionIsBlockWhenNoKeyAllowsAndUrlIsPresent() {
    let flow = FilterFlow.test(
      url: "https://unknown.com/foo",
      hostname: "unknown.com",
      bundleId: "com.foo.bar"
    )
    expect(TestFilter.scenario().newFlowDecision(flow)).toEqual(.block(.defaultNotAllowed))
  }

  func testFlowAllowedForAppWithUnrestrictedScope() {
    let flow = FilterFlow.test(ipAddress: "4.4.4.4", hostname: "abc123.com", bundleId: "com.foo")
    let key = FilterKey(key: .skeleton(scope: .bundleId("com.foo")))
    let filter = TestFilter.scenario(userKeys: [502: [key]])
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.permittedByKey(key.id)))
  }

  func testUdpFlowAllowedForAppWithUnrestrictedScope() {
    let flow = FilterFlow.test(
      ipAddress: "4.4.4.4",
      hostname: "abc123.com",
      bundleId: "com.foo",
      port: .other(333),
      ipProtocol: .udp(Int32(IPPROTO_UDP))
    )
    let key = FilterKey(key: .skeleton(scope: .bundleId("com.foo")))
    let filter = TestFilter.scenario(userKeys: [502: [key]])
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.permittedByKey(key.id)))
  }

  func testAllKeysChecked() {
    let key1 = FilterKey(key: .skeleton(scope: .bundleId("com.foo")))
    let key2 = FilterKey(key: .domain(domain: "bar.com", scope: .webBrowsers))
    let filter = TestFilter.scenario(userKeys: [502: [key1, key2]])
    expect(filter.newFlowDecision(.test(hostname: "bar.com")))
      .toEqual(.allow(.permittedByKey(key2.id)))
  }

  func testFlowAllowedForAppWithUnrestrictedScopeNoHostname() {
    let key = FilterKey(key: .skeleton(scope: .identifiedAppSlug("chrome")))
    let filter = TestFilter.scenario(userKeys: [502: [key]])
    let flow = FilterFlow.test(ipAddress: "4.4.4.4", hostname: nil)
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.permittedByKey(key.id)))
  }

  func testDnsUdpRequestsAlwaysAllowed() {
    let flow = FilterFlow(port: .dns(53), ipProtocol: .udp(Int32(IPPROTO_UDP)))
    let filter = TestFilter.scenario()
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.dnsRequest))
  }

  func testFlowRejectedWhenNoKeys() {
    let filter = TestFilter.scenario(userKeys: [:])
    expect(filter.newFlowDecision(.test())).toEqual(.block(.noUserKeys))
  }

  func testDoesNotBlockOwnRequests() {
    let cases: [(
      ip: String?,
      hostname: String?,
      url: String?,
      bundleId: String,
      decision: FilterDecision.FromFlow?
    )] =
      [
        (
          ip: nil,
          hostname: nil,
          url: nil,
          bundleId: "com.netrivet.gertrude.app",
          decision: .allow(.fromGertrudeApp)
        ),
        (
          ip: nil,
          hostname: nil,
          url: nil,
          bundleId: "WFN83LM943.com.netrivet.gertrude.app",
          decision: .allow(.fromGertrudeApp)
        ),
        (
          ip: "1.2.3.4",
          hostname: "foo.com",
          url: "https://foo.com/bar",
          bundleId: "WFN83LM943.com.netrivet.gertrude.app",
          decision: .allow(.fromGertrudeApp)
        ),
        (
          ip: nil,
          hostname: nil,
          url: nil,
          bundleId: "gertrude.app.imposter",
          decision: nil
        ),
      ]
    for (ip, hostname, url, bundleId, decision) in cases {
      let filter = TestFilter.scenario()
      let flow = FilterFlow.test(url: url, ipAddress: ip, hostname: hostname, bundleId: bundleId)
      expect(filter.newFlowDecision(flow)).toEqual(decision)
    }
  }

  func testOwnRequestStillAllowedWhenKeychainsMissing() {
    let filter = TestFilter.scenario(userKeys: [:])
    expect(filter.newFlowDecision(.test(bundleId: "com.netrivet.gertrude.app")))
      .toEqual(.allow(.fromGertrudeApp))
  }
}

// helpers

extension FilterFlow {
  static func test(
    url: String? = nil,
    ipAddress: String? = nil,
    hostname: String? = nil,
    bundleId: String? = "com.chrome",
    remoteEndpoint: String? = nil,
    userId: uid_t? = 502,
    port: Core.Port? = nil,
    ipProtocol: IpProtocol? = nil
  ) -> Self {
    FilterFlow(
      url: url,
      ipAddress: ipAddress,
      hostname: hostname,
      bundleId: bundleId,
      remoteEndpoint: remoteEndpoint,
      userId: userId,
      port: port,
      ipProtocol: ipProtocol
    )
  }
}
