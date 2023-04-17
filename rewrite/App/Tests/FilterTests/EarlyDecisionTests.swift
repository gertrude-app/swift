import XCTest
import XExpect

@testable import Filter

final class EarlyDecisionTests: XCTestCase {
  func testMissingUserIdResultsInBlock() {
    let filter = TestFilter.scenario(userIdFromAuditToken: nil, exemptUsers: [503])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.block)
  }

  func testSystemUserAllowed() {
    let filter = TestFilter.scenario(userIdFromAuditToken: 400)
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.allow)
  }

  func testExemptUserExempt() {
    let filter = TestFilter.scenario(userIdFromAuditToken: 503, exemptUsers: [503])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.allow)
  }

  func testNonExemptUserNotExempt() {
    let filter = TestFilter.scenario(userIdFromAuditToken: 502, exemptUsers: [503])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.none(502))
  }

  func testUserWithUnrestrictedScopeFilterSuspensionAllowed() {
    let filter = TestFilter.scenario(suspensions: [502: .init(scope: .unrestricted, duration: 100)])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.allow)
  }

  func testUserWithBrowserScopeFilterSuspensionNoDecision() {
    let filter = TestFilter.scenario(suspensions: [502: .init(scope: .webBrowsers, duration: 1000)])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.none(502))
  }

  func testExpiredUnrestrictedSuspensionProducesNoDecision() {
    let filter = TestFilter.scenario(suspensions: [502: .init(scope: .unrestricted, duration: -10)])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.none(502))
  }

  func testUserWithAppSlugScopedFilterSuspensionProducesNoDecision() {
    let filter = TestFilter.scenario(suspensions: [502: .init(
      scope: .single(.identifiedAppSlug("foo")),
      duration: 1000
    )])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.none(502))
  }

  func testUserWithBundleIdScopedFilterSuspensionProducesNoDecision() {
    let filter = TestFilter.scenario(suspensions: [502: .init(
      scope: .single(.bundleId("foo")),
      duration: 1000
    )])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.none(502))
  }
}
