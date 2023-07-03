import Core
import XCTest
import XExpect

@testable import App

final class BlockedRequestTests: XCTestCase {
  func testDifferingAppNotMergeable() {
    let br1 = BlockedRequest(app: .init(bundleId: "com.rofl.app"))
    let br2 = BlockedRequest(app: .init(bundleId: "com.acme.app"))
    expect(br1.mergeable(with: br2)).toBeFalse()
  }

  func testDifferingProtocolsNotMergeable() {
    let br1 = BlockedRequest(app: .mock, url: "/", ipProtocol: .tcp(1))
    let br2 = BlockedRequest(app: .mock, url: "/", ipProtocol: .udp(1))
    expect(br1.mergeable(with: br2)).toBeFalse()
  }

  func testDifferentUrlsButSameHostnameMergeable() {
    let br1 = BlockedRequest(app: .mock, url: "https://foo.com/1", hostname: "foo.com")
    let br2 = BlockedRequest(app: .mock, url: "https://foo.com/2", hostname: "foo.com")
    expect(br1.mergeable(with: br2)).toBeTrue()
  }

  func testOnlyIpButSameMergeable() {
    let br1 = BlockedRequest(app: .mock, ipAddress: "1.2.3.4")
    let br2 = BlockedRequest(app: .mock, ipAddress: "1.2.3.4")
    expect(br1.mergeable(with: br2)).toBeTrue()
  }

  func testSameUrlsMergableDespiteOtherDifferences() {
    let br1 = BlockedRequest(app: .mock, url: "https://a.com/1", ipAddress: "1.2.3.4")
    let br2 = BlockedRequest(app: .mock, url: "https://a.com/1", ipAddress: "3.2.3.4")
    expect(br1.mergeable(with: br2)).toBeTrue()
  }
}
