import Dependencies
import XCTest
import XExpect

@testable import Api

final class SubscriptionManagerTests: ApiTestCase {
  override func setUp() async throws {
    Current.date = { .reference }
  }

  func testAdvanceExpiredFn() async throws {
    try await Admin.deleteAll()
    try await DeletedEntity.deleteAll()

    let nonExpired = Admin.random {
      $0.subscriptionStatus = .trialing
      $0.subscriptionStatusExpiration = .reference.advanced(by: .days(40))
    }

    let trialEndingSoon = Admin.random {
      $0.subscriptionStatus = .trialing
      $0.subscriptionStatusExpiration = .reference.advanced(by: .days(-1))
    }

    let shouldDelete = Admin.random {
      $0.subscriptionStatus = .pendingAccountDeletion
      $0.subscriptionStatusExpiration = .reference.advanced(by: .days(-1))
    }

    try await Admin.create([nonExpired, trialEndingSoon, shouldDelete])
    try await SubscriptionManager().advanceExpired()

    let retrievedNonExpired = try await Admin.find(nonExpired.id)
    expect(retrievedNonExpired.subscriptionStatus).toEqual(.trialing)
    expect(retrievedNonExpired.subscriptionStatusExpiration)
      .toEqual(.reference.advanced(by: .days(40)))

    let retrievedTrialEndingSoon = try await Admin.find(trialEndingSoon.id)
    expect(retrievedTrialEndingSoon.subscriptionStatus).toEqual(.trialExpiringSoon)
    expect(retrievedTrialEndingSoon.subscriptionStatusExpiration)
      .toEqual(.reference.advanced(by: .days(7)))

    let retrievedShouldDelete = try? await Admin.find(shouldDelete.id)
    expect(retrievedShouldDelete).toBeNil()
    let retrievedDeleted = try await DeletedEntity.query().all()
    expect(retrievedDeleted.count).toEqual(1)
    XCTAssert(retrievedDeleted[0].data.contains(shouldDelete.id.lowercased))

    expect(sent.postmarkEmails.count).toEqual(1)
    expect(sent.postmarkEmails[0].to).toEqual(trialEndingSoon.email.rawValue)
    XCTAssert(sent.postmarkEmails[0].subject.contains("trial ending soon"))
  }

  func testNonExpiredStateDoesNotUpdate() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .overdue
      $0.subscriptionStatusExpiration = .distantFuture
    }
    expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toBeNil()
  }

  func testTrialExpiringSoon() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .trialing
      $0.subscriptionStatusExpiration = .epoch
    }
    expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(status: .trialExpiringSoon, expiration: .reference.advanced(by: .days(7))),
      email: .trialEndingSoon
    ))
  }

  func testTrialEnded_NotOnboarded() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .trialExpiringSoon
      $0.subscriptionStatusExpiration = .epoch
    }
    expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(status: .overdue, expiration: .reference.advanced(by: .days(14))),
      email: nil // <-- no email, they never onboarded
    ))
  }

  func testTrialEnded_Onboarded() async throws {
    let admin = try await Entities.admin {
      $0.subscriptionStatus = .trialExpiringSoon
      $0.subscriptionStatusExpiration = .epoch
    }.withOnboardedChild().model
    expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(status: .overdue, expiration: .reference.advanced(by: .days(14))),
      email: .trialEndedToOverdue
    ))
  }

  func testOverdueToUnpaid_NotOnboarded() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .overdue
      $0.subscriptionStatusExpiration = .epoch
    }
    expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(status: .unpaid, expiration: .reference.advanced(by: .days(365))),
      email: nil // <-- no email, they never onboarded
    ))
  }

  func testOverdueToUnpaid_Onboarded() async throws {
    let admin = try await Entities.admin {
      $0.subscriptionStatus = .overdue
      $0.subscriptionStatusExpiration = .epoch
    }.withOnboardedChild().model
    expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(status: .unpaid, expiration: .reference.advanced(by: .days(365))),
      email: .overdueToUnpaid
    ))
  }

  func testUnpaidToPendingDeletion_NotOnboarded() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .unpaid
      $0.subscriptionStatusExpiration = .epoch
    }
    expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(
        status: .pendingAccountDeletion,
        expiration: .reference.advanced(by: .days(30))
      ),
      email: nil // <-- no email, they never onboarded
    ))
  }

  func testUnpaidToPendingDeletion_Onboarded() async throws {
    let admin = try await Entities.admin {
      $0.subscriptionStatus = .unpaid
      $0.subscriptionStatusExpiration = .epoch
    }.withOnboardedChild().model
    expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(
        status: .pendingAccountDeletion,
        expiration: .reference.advanced(by: .days(30))
      ),
      email: .unpaidToPendingDelete
    ))
  }

  func testPendingDeletionToDeleted() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .pendingAccountDeletion
      $0.subscriptionStatusExpiration = .epoch
    }
    expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .delete(reason: "account unpaid > 1yr"),
      email: nil
    ))
  }

  func testEmailUnverifiedToDeleted() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .pendingEmailVerification
      $0.subscriptionStatusExpiration = .epoch
    }
    expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .delete(reason: "email never verified"),
      email: .deleteEmailUnverified
    ))
  }

  func testPaidToOverdue() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .paid
      $0.subscriptionStatusExpiration = .epoch
    }
    expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(status: .overdue, expiration: .reference.advanced(by: .days(14))),
      email: .paidToOverdue
    ))
  }

  func testPaidToOverdueButStripeSaysPaid() async throws {
    let admin = Admin.empty {
      $0.subscriptionId = .init(rawValue: "sub-123")
      $0.subscriptionStatus = .paid
      $0.subscriptionStatusExpiration = .epoch
    }

    let nextExpiration = Date.reference.advanced(by: .days(27))

    try await withDependencies {
      $0.stripe.getSubscription = { subsId in
        expect(subsId).toEqual("sub-123")
        return .init(
          id: subsId,
          status: .active,
          customer: "cs-123",
          currentPeriodEnd: Int(Date.epoch.distance(to: nextExpiration))
        )
      }
    } operation: {
      expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
        action: .update(status: .paid, expiration: nextExpiration.advanced(by: .days(2))),
        email: nil
      ))
    }
  }

  func testOverdueToPaid() async throws {
    let admin = Admin.empty {
      $0.subscriptionId = .init(rawValue: "sub-123")
      $0.subscriptionStatus = .overdue
      $0.subscriptionStatusExpiration = .epoch
    }
    let nextExpiration = Date.reference.advanced(by: .days(27))
    try await withDependencies {
      $0.stripe.getSubscription = { subsId in
        expect(subsId).toEqual("sub-123")
        return .init(
          id: subsId,
          status: .active,
          customer: "cs-123",
          currentPeriodEnd: Int(Date.epoch.distance(to: nextExpiration))
        )
      }
    } operation: {
      expect(try await SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
        action: .update(status: .paid, expiration: nextExpiration.advanced(by: .days(2))),
        email: nil
      ))
    }
  }
}
