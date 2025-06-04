import Dependencies
import XCTest
import XExpect

@testable import Api

final class SubscriptionManagerTests: ApiTestCase, @unchecked Sendable {
  func testAdvanceExpiredFn() async throws {
    try await self.db.delete(all: Admin.self)
    try await self.db.delete(all: DeletedEntity.self)

    let nonExpired = Admin.random {
      $0.subscriptionStatus = .trialing
      $0.subscriptionStatusExpiration = .reference + .days(40)
    }

    let trialEndingSoon = Admin.random {
      $0.subscriptionStatus = .trialing
      $0.subscriptionStatusExpiration = .reference - .days(1)
    }

    let shouldDelete = Admin.random {
      $0.subscriptionStatus = .pendingAccountDeletion
      $0.subscriptionStatusExpiration = .reference - .days(1)
    }

    try await self.db.create([nonExpired, trialEndingSoon, shouldDelete])
    try await SubscriptionManager().advanceExpired()

    let retrievedNonExpired = try await self.db.find(nonExpired.id)
    expect(retrievedNonExpired.subscriptionStatus).toEqual(.trialing)
    expect(retrievedNonExpired.subscriptionStatusExpiration)
      .toEqual(.reference + .days(40))

    let retrievedTrialEndingSoon = try await self.db.find(trialEndingSoon.id)
    expect(retrievedTrialEndingSoon.subscriptionStatus).toEqual(.trialExpiringSoon)
    expect(retrievedTrialEndingSoon.subscriptionStatusExpiration)
      .toEqual(.reference + .days(3))

    let retrievedShouldDelete = try? await self.db.find(shouldDelete.id)
    expect(retrievedShouldDelete).toBeNil()
    let retrievedDeleted = try await self.db.select(all: DeletedEntity.self)
    expect(retrievedDeleted.count).toEqual(1)
    XCTAssert(retrievedDeleted[0].data.contains(shouldDelete.id.lowercased))

    expect(sent.emails.count).toEqual(1)
    expect(sent.emails[0].to).toEqual(trialEndingSoon.email.rawValue)
    expect(sent.emails[0].template).toBe("trial-ending-soon")
  }

  func testNonExpiredStateDoesNotUpdate() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .overdue
      $0.subscriptionStatusExpiration = .distantFuture
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toBeNil()
  }

  func testTrialExpiringSoon() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .trialing
      $0.subscriptionStatusExpiration = .epoch
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(status: .trialExpiringSoon, expiration: .reference + .days(3)),
      email: .trialEndingSoon(length: 21, remaining: 3)
    ))
  }

  func testLegacyLongTrialPeriod() async throws {
    let parent = Admin.random {
      $0.subscriptionStatus = .trialing
      $0.trialPeriodDays = 60 // <-- legacy 60-day trial
      $0.subscriptionStatusExpiration = .epoch
    }

    await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
      action: .update(status: .trialExpiringSoon, expiration: .reference + .days(7)),
      email: .trialEndingSoon(length: 60, remaining: 7)
    ))
  }

  func testTrialEnded_NotOnboarded() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .trialExpiringSoon
      $0.subscriptionStatusExpiration = .epoch
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(status: .overdue, expiration: .reference + .days(7)),
      email: nil // <-- no email, they never onboarded
    ))
  }

  func testTrialEnded_Onboarded() async throws {
    let admin = try await self.parent {
      $0.subscriptionStatus = .trialExpiringSoon
      $0.subscriptionStatusExpiration = .epoch
    }.withOnboardedChild().model
    await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(status: .overdue, expiration: .reference + .days(7)),
      email: .trialEndedToOverdue(length: 21)
    ))
  }

  func testOverdueToUnpaid_NotOnboarded() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .overdue
      $0.subscriptionStatusExpiration = .epoch
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(status: .unpaid, expiration: .reference + .days(365)),
      email: nil // <-- no email, they never onboarded
    ))
  }

  func testOverdueToUnpaid_Onboarded() async throws {
    let admin = try await self.parent {
      $0.subscriptionStatus = .overdue
      $0.subscriptionStatusExpiration = .epoch
    }.withOnboardedChild().model
    await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(status: .unpaid, expiration: .reference + .days(365)),
      email: .overdueToUnpaid
    ))
  }

  func testUnpaidToPendingDeletion_NotOnboarded() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .unpaid
      $0.subscriptionStatusExpiration = .epoch
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(
        status: .pendingAccountDeletion,
        expiration: .reference + .days(30)
      ),
      email: nil // <-- no email, they never onboarded
    ))
  }

  func testUnpaidToPendingDeletion_Onboarded() async throws {
    let admin = try await self.parent {
      $0.subscriptionStatus = .unpaid
      $0.subscriptionStatusExpiration = .epoch
    }.withOnboardedChild().model
    await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(
        status: .pendingAccountDeletion,
        expiration: .reference + .days(30)
      ),
      email: .unpaidToPendingDelete
    ))
  }

  func testPendingDeletionToDeleted() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .pendingAccountDeletion
      $0.subscriptionStatusExpiration = .epoch
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .delete(reason: "account unpaid > 1yr"),
      email: nil
    ))
  }

  func testEmailUnverifiedToDeleted() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .pendingEmailVerification
      $0.subscriptionStatusExpiration = .epoch
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .delete(reason: "email never verified"),
      email: .deleteEmailUnverified
    ))
  }

  func testPaidToOverdue() async throws {
    let admin = Admin.empty {
      $0.subscriptionStatus = .paid
      $0.subscriptionStatusExpiration = .epoch
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
      action: .update(status: .overdue, expiration: .reference + .days(14)),
      email: .paidToOverdue
    ))
  }

  func testPaidToOverdueButStripeSaysPaid() async throws {
    let admin = Admin.empty {
      $0.subscriptionId = .init(rawValue: "sub-123")
      $0.subscriptionStatus = .paid
      $0.subscriptionStatusExpiration = .epoch
    }

    let nextExpiration = Date.reference + .days(27)

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
      await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
        action: .update(status: .paid, expiration: nextExpiration + .days(2)),
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
    let nextExpiration = Date.reference + .days(27)
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
      await expect(try SubscriptionManager().subscriptionUpdate(for: admin)).toEqual(.init(
        action: .update(status: .paid, expiration: nextExpiration + .days(2)),
        email: nil
      ))
    }
  }
}

private extension ParentEntities {
  func withOnboardedChild(
    config: (inout Child, inout ComputerUser, inout Computer) -> Void = { _, _, _ in }
  ) async throws -> ParentWithOnboardedChildEntities {
    @Dependency(\.db) var db
    var child = Child.random { $0.parentId = model.id }
    var adminDevice = Computer.random { $0.parentId = model.id }
    var userDevice = ComputerUser.random {
      $0.childId = child.id
      $0.computerId = adminDevice.id
    }
    config(&child, &userDevice, &adminDevice)
    try await db.create(child)
    try await db.create(adminDevice)
    try await db.create(userDevice)
    return .init(
      model: self.model,
      token: self.token,
      child: child,
      computerUser: userDevice,
      computer: adminDevice
    )
  }
}
