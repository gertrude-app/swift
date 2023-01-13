import Shared
import XCTest

@testable import FilterCore

class FilterDecisionMakerUserIdTests: FilterDecisionMakerTestCase {
  func testMissingUserIdResultsInBlock() {
    let decision = maker.make(userId: nil, exemptedUsers: nil)
    assertDecision(decision, .block, .missingUserId)
  }

  func testSystemUserAllowed() {
    let decision1 = maker.make(userId: 400, exemptedUsers: nil)
    assertDecision(decision1, .allow, .systemUser)
    let decision2 = maker.make(userId: 400, exemptedUsers: [503])
    assertDecision(decision2, .allow, .systemUser)
  }

  func testExemptedUserExempt() {
    let decision = maker.make(userId: 501, exemptedUsers: [501])
    assertDecision(decision, .allow, .userIsExempt)
  }

  func testNonExemptedUserNotExempt() {
    let decision = maker.make(userId: 501, exemptedUsers: [502])
    XCTAssertNil(decision)
  }

  func testUserWithUnrestrictedScopeFilterSuspensionAllowed() {
    maker.suspensions.set(.init(scope: .unrestricted, duration: 1000), userId: 501)
    let decision = maker.make(userId: 501, exemptedUsers: nil)
    XCTAssertEqual(decision?.verdict, .allow)
    XCTAssertEqual(decision?.reason, .filterSuspended)
  }

  func testUserWithBrowserScopeFilterSuspensionProducesNilDecision() {
    maker.suspensions.set(.init(scope: .webBrowsers, duration: 1000), userId: 501)
    let decision = maker.make(userId: 501, exemptedUsers: nil)
    XCTAssertNil(decision)
  }

  func testExpiredUnrestrictedSuspensionProducesNil() {
    maker.suspensions.set(.init(scope: .unrestricted, duration: -1000), userId: 501)
    let decision = maker.make(userId: 501, exemptedUsers: nil)
    XCTAssertNil(decision)
  }

  func testUserWithAppSlugScopedFilterSuspensionProducesNil() {
    maker.suspensions.set(
      .init(scope: .single(.identifiedAppSlug("foo")), duration: 1000),
      userId: 501
    )
    let decision = maker.make(userId: 501, exemptedUsers: nil)
    XCTAssertNil(decision)
  }

  func testUserWithBundleIdScopedFilterSuspensionProducesNil() {
    maker.suspensions.set(
      .init(scope: .single(.bundleId("com.foo")), duration: 1000),
      userId: 501
    )
    let decision = maker.make(userId: 501, exemptedUsers: nil)
    XCTAssertNil(decision)
  }
}
