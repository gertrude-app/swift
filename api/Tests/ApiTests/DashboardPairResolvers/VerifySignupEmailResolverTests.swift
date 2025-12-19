import Dependencies
import DuetSQL
import XCTest
import XExpect
import XStripe

@testable import Api

final class VerifySignupEmailResolverTests: ApiTestCase, @unchecked Sendable {
  let context = Context.mock

  func testVerifySignupEmailSetsSubscriptionStatusAndCreatesNotificationMethod() async throws {
    let parent = try await self.parent(with: \.subscriptionStatus, of: .pendingEmailVerification)
    let token = await with(dependency: \.ephemeral).createParentIdToken(parent.id)

    let output = try await VerifySignupEmail.resolve(with: .init(token: token), in: self.context)

    let retrieved = try await self.db.find(parent.id)
    let method = try await Parent.NotificationMethod.query()
      .where(.parentId == parent.id)
      .first(in: self.db)

    expect(output.adminId).toEqual(parent.id)
    expect(retrieved.subscriptionStatus).toEqual(.trialing)
    expect(retrieved.subscriptionStatusExpiration).toEqual(.reference.advanced(by: .days(18)))
    expect(method.config).toEqual(.email(email: parent.email.rawValue))
  }

  func testVerifyingWithExpiredTokenErrorsButSendsNewVerification() async throws {
    let parent = try await self.parent(with: \.subscriptionStatus, of: .pendingEmailVerification)
    let token = await with(dependency: \.ephemeral).createParentIdToken(
      parent.id,
      expiration: Date.reference - .days(1),
    )

    let result = await VerifySignupEmail.result(with: .init(token: token), in: self.context)

    expect(result).toBeError(containing: "expired, but we sent a new verification email")
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails[0].to).toEqual(parent.email.rawValue)
    expect(sent.emails[0].template).toBe("initial-signup")
  }

  func testExpiredTokenForAlreadyVerifiedParentErrorsWithHelpfulMessage() async throws {
    try await withDependencies {
      $0.date = .init { Date() }
    } operation: {
      let parent = try await self
        .parent(with: \.subscriptionStatus, of: .trialing) // <- already verified
      let token = await with(dependency: \.ephemeral).createParentIdToken(
        parent.id,
        expiration: Date() - .days(1),
      )

      let result = await VerifySignupEmail.result(with: .init(token: token), in: self.context)
      expect(result).toBeError(containing: "already verified")
      expect(sent.emails).toHaveCount(0) // no email sent, they're already verified
    }
  }

  func testPreviouslyRetrievedTokenForVerifiedParentErrors() async throws {
    let parent = try await self.parent(with: \.subscriptionStatus, of: .pendingEmailVerification)
    let token = await with(dependency: \.ephemeral).createParentIdToken(parent.id)

    // first use succeeds
    _ = try await VerifySignupEmail.resolve(with: .init(token: token), in: self.context)

    // second use of same token fails
    let result = await VerifySignupEmail.result(with: .init(token: token), in: self.context)
    expect(result).toBeError(containing: "already verified")
  }

  func testPreviouslyRetrievedTokenForStillPendingParentResendsEmail() async throws {
    let parent = try await self.parent(with: \.subscriptionStatus, of: .pendingEmailVerification)
    let ephemeral = with(dependency: \.ephemeral)
    let token = await ephemeral.createParentIdToken(parent.id)

    // simulate token being retrieved but parent somehow still pending
    _ = await ephemeral.parentIdFromToken(token)

    // manually reset the parent to pending (simulating edge case)
    var retrieved = try await self.db.find(parent.id)
    retrieved.subscriptionStatus = .pendingEmailVerification
    try await self.db.update(retrieved)

    let result = await VerifySignupEmail.result(with: .init(token: token), in: self.context)
    expect(result).toBeError(containing: "we sent a new verification email")
    expect(sent.emails).toHaveCount(1)
  }

  func testVerifySignupEmailDoesntChangeAdminUserSubscriptionStatusWhenNotPending() async throws {
    let parent = try await self
      .parent(with: \.subscriptionStatus, of: .trialing) // <- not pending
    let token = await with(dependency: \.ephemeral)
      .createParentIdToken(parent.id)

    let output = try await VerifySignupEmail.resolve(with: .init(token: token), in: self.context)

    let retrieved = try await self.db.find(parent.id)

    expect(output.adminId).toEqual(parent.id)
    expect(retrieved.subscriptionStatus).toEqual(.trialing) // <-- not changed
  }

  func testAttemptToLoginWhenEmailNotVerifiedBlocksAndSendsEmail() async throws {
    let parent = try await self.parent {
      $0.subscriptionStatus = .pendingEmailVerification
      $0.password = "lol-lol-lol"
    }

    let result = await Login.result(
      with: .init(email: parent.email.rawValue, password: "lol-lol-lol"),
      in: self.context,
    )

    expect(result).toBeError(containing: "until your email is verified")
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails[0].to).toEqual(parent.email.rawValue)
    expect(sent.emails[0].template).toBe("initial-signup")
  }
}
