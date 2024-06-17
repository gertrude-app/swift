import Core
import XCTest
import XExpect

@testable import App

final class BlockedRequestTests: XCTestCase {
  func testDifferingAppNotMergeable() {
    let br1 = BlockedRequest(app: .init(bundleId: "com.rofl.app"))
    let br2 = BlockedRequest(app: .init(bundleId: "com.acme.app"))
    expect(br1.mergeable(with: br2)).toBeFalse()
    expect(br2.mergeable(with: br1)).toBeFalse()
  }

  func testDifferingProtocolsNotMergeable() {
    let br1 = BlockedRequest(app: .mock, url: "/", ipProtocol: .tcp(1))
    let br2 = BlockedRequest(app: .mock, url: "/", ipProtocol: .udp(1))
    expect(br1.mergeable(with: br2)).toBeFalse()
    expect(br2.mergeable(with: br1)).toBeFalse()
  }

  func testDifferentUrlsButSameHostnameMergeable() {
    let br1 = BlockedRequest(app: .mock, url: "https://foo.com/1", hostname: "foo.com")
    let br2 = BlockedRequest(app: .mock, url: "https://foo.com/2", hostname: "foo.com")
    expect(br1.mergeable(with: br2)).toBeTrue()
    expect(br2.mergeable(with: br1)).toBeTrue()
  }

  func testOnlyIpButSameMergeable() {
    let br1 = BlockedRequest(app: .mock, ipAddress: "1.2.3.4")
    let br2 = BlockedRequest(app: .mock, ipAddress: "1.2.3.4")
    expect(br1.mergeable(with: br2)).toBeTrue()
    expect(br2.mergeable(with: br1)).toBeTrue()
  }

  func testSameIpButNowWithHostnameNotMergable() {
    let br1 = BlockedRequest(app: .mock, hostname: nil, ipAddress: "1.2.3.4")
    // second request comes in with same IP address, but this one has a hostname
    // so we don't want to merge, so they can see more hostnames instead of ip addresses
    let br2 = BlockedRequest(app: .mock, hostname: "a3.espncdn.com", ipAddress: "1.2.3.4")
    expect(br1.mergeable(with: br2)).toBeFalse() // <- prefer to show hostname
    expect(br2.mergeable(with: br1)).toBeTrue() // <- don't show only ip if we have hostname
  }

  func testSameIpButNowWithUrlNotMergable() {
    let br1 = BlockedRequest(
      app: .mock,
      url: nil,
      hostname: nil,
      ipAddress: "1.2.3.4"
    )
    let br2 = BlockedRequest(
      app: .mock,
      url: "https://a.com", // <- now have url for same ip, we WANT to show it
      hostname: nil,
      ipAddress: "1.2.3.4"
    )
    expect(br1.mergeable(with: br2)).toBeFalse() // <- prefer to show url
    expect(br2.mergeable(with: br1)).toBeTrue() // <- don't show only ip if we have url
  }

  func testSameUrlsMergableDespiteOtherDifferences() {
    let br1 = BlockedRequest(app: .mock, url: "https://a.com/1", ipAddress: "1.2.3.4")
    let br2 = BlockedRequest(app: .mock, url: "https://a.com/1", ipAddress: "3.2.3.4")
    expect(br1.mergeable(with: br2)).toBeTrue()
    expect(br2.mergeable(with: br1)).toBeTrue()
  }
}
