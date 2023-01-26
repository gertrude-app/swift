import Foundation
import Shared
import SharedCore
import XCTest

@testable import FilterCore

class FilterDecisionMakerTestCase: XCTestCase {
  var maker = FilterDecisionMaker()

  override func setUp() {
    maker = FilterDecisionMaker()
    setOnlyKey(.domain(domain: "some-random-domain.com", scope: .single(.bundleId("com.random"))))
    maker.appDescriptorFactory = .init(appIdManifest: .init(
      apps: ["chrome": ["com.chrome"]],
      displayNames: ["chrome": "Chrome"],
      categories: ["browser": ["chrome"]]
    ))
  }

  @discardableResult
  func setOnlyKey(_ key: Key, userId: uid_t = 501) -> UUID {
    let userKey = FilterKey(id: .init(), type: key)
    maker.userKeys[userId] = [userKey]
    return userKey.id
  }

  @discardableResult
  func addKey(_ key: Key, userId: uid_t = 501) -> UUID {
    let userKey = FilterKey(id: .init(), type: key)
    maker.userKeys[userId, default: []].append(userKey)
    return userKey.id
  }

  func addSuspension(_ scope: AppScope, duration: Int = 1000, userId: uid_t = 501) {
    maker.suspensions.set(
      .init(scope: scope, duration: .init(rawValue: duration)),
      userId: userId
    )
  }
}

func assertDecision(
  _ decision: FilterDecision?,
  _ verdict: NetworkDecisionVerdict,
  _ reason: NetworkDecisionReason,
  _ keyId: UUID? = nil,
  file: StaticString = #file,
  line: UInt = #line
) {
  XCTAssertNotNil(decision, file: file, line: line)
  guard let decision = decision else { return }
  XCTAssertEqual(decision.verdict, verdict, file: file, line: line)
  XCTAssertEqual(decision.reason, reason, file: file, line: line)
  if let keyId = keyId {
    XCTAssertEqual(decision.responsibleKeyId, keyId, file: file, line: line)
  }
}

extension FilterFlow {
  static func test(
    url: String? = nil,
    ipAddress: String? = nil,
    hostname: String? = nil,
    bundleId: String? = "com.chrome",
    remoteEndpoint: String? = nil,
    sourceAuditToken: Data? = nil,
    userId: uid_t? = 501,
    port: NetworkPort? = nil,
    ipProtocol: IpProtocol? = nil
  ) -> Self {
    FilterFlow(
      url: url,
      ipAddress: ipAddress,
      hostname: hostname,
      bundleId: bundleId,
      remoteEndpoint: remoteEndpoint,
      sourceAuditToken: sourceAuditToken,
      userId: userId,
      port: port,
      ipProtocol: ipProtocol
    )
  }
}
