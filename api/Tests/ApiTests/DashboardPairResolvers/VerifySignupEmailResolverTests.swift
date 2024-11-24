import Dependencies
import DuetSQL
import XCTest
import XExpect
import XStripe

@testable import Api

final class VerifySignupEmailResolverTests: ApiTestCase {
  let context = Context.mock

  func testVerifySignupEmailSetsSubscriptionStatusAndCreatesNotificationMethod() async throws {
    let admin = try await self.admin(with: \.subscriptionStatus, of: .pendingEmailVerification)
    let token = await with(dependency: \.ephemeral).createAdminIdToken(admin.id)

    let output = try await VerifySignupEmail.resolve(with: .init(token: token), in: self.context)

    let retrieved = try await self.db.find(admin.id)
    let method = try await AdminVerifiedNotificationMethod.query()
      .where(.adminId == admin.id)
      .first(in: self.db)

    expect(output.adminId).toEqual(admin.id)
    expect(retrieved.subscriptionStatus).toEqual(.trialing)
    expect(retrieved.subscriptionStatusExpiration).toEqual(.reference.advanced(by: .days(53)))
    expect(method.config).toEqual(.email(email: admin.email.rawValue))
  }

  func testVerifyingWithExpiredTokenErrorsButSendsNewVerification() async throws {
    let admin = try await self.admin(with: \.subscriptionStatus, of: .pendingEmailVerification)
    let token = await with(dependency: \.ephemeral).createAdminIdToken(
      admin.id,
      expiration: Date.reference - .days(1)
    )

    let result = await VerifySignupEmail.result(with: .init(token: token), in: self.context)

    expect(result).toBeError(containing: "expired, but we sent a new verification email")
    expect(sent.postmarkEmails).toHaveCount(1)
    expect(sent.postmarkEmails[0].to).toEqual(admin.email.rawValue)
    expect(sent.postmarkEmails[0].body).toContain("verify your email address")
  }

  func testReVerifyingExpiredTokenErrorsWithHelpfulMessage() async throws {
    try await withDependencies {
      $0.date = .init { Date() }
    } operation: {
      let admin = try await self
        .admin(with: \.subscriptionStatus, of: .trialing) // <- already verified
      let token = await with(dependency: \.ephemeral).createAdminIdToken(
        admin.id,
        expiration: Date() - .days(1)
      )

      let result = await VerifySignupEmail.result(with: .init(token: token), in: self.context)
      expect(result).toBeError(containing: "already verified")
    }
  }

  func testVerifySignupEmailDoesntChangeAdminUserSubscriptionStatusWhenNotPending() async throws {
    let admin = try await self
      .admin(with: \.subscriptionStatus, of: .trialing) // <- not pending
    let token = await with(dependency: \.ephemeral)
      .createAdminIdToken(admin.id)

    let output = try await VerifySignupEmail.resolve(with: .init(token: token), in: self.context)

    let retrieved = try await self.db.find(admin.id)

    expect(output.adminId).toEqual(admin.id)
    expect(retrieved.subscriptionStatus).toEqual(.trialing) // <-- not changed
  }

  func testAttemptToLoginWhenEmailNotVerifiedBlocksAndSendsEmail() async throws {
    let admin = try await self.admin {
      $0.subscriptionStatus = .pendingEmailVerification
      $0.password = "lol-lol-lol"
    }

    let result = await Login.result(
      with: .init(email: admin.email.rawValue, password: "lol-lol-lol"),
      in: self.context
    )

    expect(result).toBeError(containing: "until your email is verified")
    expect(sent.postmarkEmails).toHaveCount(1)
    expect(sent.postmarkEmails[0].to).toEqual(admin.email.rawValue)
    expect(sent.postmarkEmails[0].body).toContain("verify your email address")
  }
}
