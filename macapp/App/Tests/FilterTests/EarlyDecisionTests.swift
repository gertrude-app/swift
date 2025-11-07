import Core
import Gertie
import XCTest
import XExpect

@testable import Filter

final class EarlyDecisionTests: XCTestCase {
  func testMissingUserIdResultsInBlock() {
    let filter = TestFilter.scenario(userIdFromAuditToken: nil, exemptUsers: [503])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.block(.missingUserId))
  }

  func testSystemUserAllowed() {
    let filter = TestFilter.scenario(userIdFromAuditToken: 400)
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.allow(.systemUser(400)))
  }

  func testExemptUserExempt() {
    let filter = TestFilter.scenario(userIdFromAuditToken: 503, exemptUsers: [503])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.allow(.exemptUser(503)))
  }

  func testNonExemptUserNotExempt() {
    let filter = TestFilter.scenario(userIdFromAuditToken: 502, exemptUsers: [503])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.none(502))
  }

  func testExemptUserNotConsideredAwol() {
    let filter = TestFilter.scenario(
      userIdFromAuditToken: 502,
      macappsAliveUntil: [:], // <-- AWOL
      exemptUsers: [502], // <-- but exempt
    )
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.allow(.exemptUser(502)))
  }

  func testBlockedByDowntime() {
    let downtime = PlainTimeWindow(
      start: .init(hour: 22, minute: 0),
      end: .init(hour: 5, minute: 0),
    )

    let cases: [(hour: Int, minute: Int, decision: FilterDecision.FromUserId)] = [
      (hour: 21, minute: 59, decision: .none(502)),
      (hour: 22, minute: 0, decision: .blockDuringDowntime(502)),
      (hour: 23, minute: 39, decision: .blockDuringDowntime(502)),
      (hour: 2, minute: 44, decision: .blockDuringDowntime(502)),
      (hour: 5, minute: 0, decision: .none(502)),
      (hour: 5, minute: 1, decision: .none(502)),
    ]
    for (hour, minute, decision) in cases {
      let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute))!
      let filter = TestFilter.scenario(
        userIdFromAuditToken: 502,
        userDowntime: [502: downtime],
        date: .constant(date),
      )
      expect(filter.earlyUserDecision(auditToken: .init())).toEqual(decision)
    }
  }

  func testDowntimeTrumpsExemption() {
    let downtime = PlainTimeWindow(
      start: .init(hour: 22, minute: 0),
      end: .init(hour: 5, minute: 0),
    )
    let withinDowntime = Calendar.current.date(from: DateComponents(hour: 23, minute: 33))!
    let filter = TestFilter.scenario(
      userIdFromAuditToken: 502,
      userDowntime: [502: downtime], // has downtime...
      date: .constant(withinDowntime),
      exemptUsers: [502], // <-- ... AND is EXEMPT, but downtime wins
    )
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.blockDuringDowntime(502))
  }

  func testDowntimeTrumpsSuspension() {
    let downtime = PlainTimeWindow(
      start: .init(hour: 22, minute: 0),
      end: .init(hour: 5, minute: 0),
    )
    let withinDowntime = Calendar.current.date(from: DateComponents(hour: 23, minute: 33))!
    let filter = TestFilter.scenario(
      userIdFromAuditToken: 502,
      userDowntime: [502: downtime], // has downtime...
      date: .constant(withinDowntime),
      suspensions: [502: .init( // <-- AND is SUSPENDED, but downtime wins
        scope: .unrestricted,
        duration: 1000,
      )],
    )
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.blockDuringDowntime(502))
  }

  func testDowntimeNotAppliedToOtherUser() {
    let downtime = PlainTimeWindow(
      start: .init(hour: 22, minute: 0),
      end: .init(hour: 5, minute: 0),
    )
    let withinDowntime = Calendar.current.date(from: DateComponents(hour: 23, minute: 33))!
    let filter = TestFilter.scenario(
      userIdFromAuditToken: 502,
      userDowntime: [503: downtime], // <-- downtime exists, but for another user
      date: .constant(withinDowntime),
    )
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.none(502))
  }

  func testUserWithUnrestrictedScopeFilterSuspensionAllowed() {
    let filter = TestFilter.scenario(suspensions: [502: .init(scope: .unrestricted, duration: 100)])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.allow(.filterSuspended(502)))
  }

  func testFilterSuspensionAllowNotGrantedEarlyIfMacappAppearsAWOL() {
    let filter = TestFilter.scenario(
      macappsAliveUntil: [:],
      suspensions: [502: .init(scope: .unrestricted, duration: 100)],
    )
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.none(502))
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
      duration: 1000,
    )])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.none(502))
  }

  func testUserWithBundleIdScopedFilterSuspensionProducesNoDecision() {
    let filter = TestFilter.scenario(suspensions: [502: .init(
      scope: .single(.bundleId("foo")),
      duration: 1000,
    )])
    expect(filter.earlyUserDecision(auditToken: .init())).toEqual(.none(502))
  }
}
