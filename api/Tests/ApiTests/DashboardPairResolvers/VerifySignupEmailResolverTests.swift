import DuetMock
import DuetSQL
import XCTest
import XExpect
import XStripe

@testable import Api

final class VerifySignupEmailResolverTests: ApiTestCase {
  let context = Context.mock

  func testVerifySignupEmailSetsSubsriptionStatusAndCreatesNotificationMethod() async throws {
    let admin = try await Entities.admin { $0.subscriptionStatus = .pendingEmailVerification }
    let token = await Current.ephemeral.createAdminIdToken(admin.id)

    let output = try await VerifySignupEmail.resolve(with: .init(token: token), in: context)

    let retrieved = try await Current.db.find(admin.id)
    let method = try await Current.db.query(AdminVerifiedNotificationMethod.self)
      .where(.adminId == admin.id)
      .first()

    expect(output.adminId).toEqual(admin.id)
    expect(retrieved.subscriptionStatus).toEqual(.trialing)
    expect(method.config).toEqual(.email(email: admin.email.rawValue))
  }

  func testVerifyingWithExpiredTokenErrorsButSendsNewVerification() async throws {
    let admin = try await Entities.admin { $0.subscriptionStatus = .pendingEmailVerification }
    let token = await Current.ephemeral.createAdminIdToken(
      admin.id,
      expiration: Current.date().advanced(by: .days(-1))
    )

    let result = await VerifySignupEmail.result(with: .init(token: token), in: context)

    expect(result).toBeError(containing: "expired, but we sent a new verification email")
    expect(sent.postmarkEmails).toHaveCount(1)
    expect(sent.postmarkEmails[0].to).toEqual(admin.email.rawValue)
    expect(sent.postmarkEmails[0].html).toContain("verify your email address")
  }

  func testReVerifyingExpiredTokenErrorsWithHelpfulMessage() async throws {
    let admin = try await Entities
      .admin { $0.subscriptionStatus = .trialing } // <-- already verified
    let token = await Current.ephemeral.createAdminIdToken(
      admin.id,
      expiration: Current.date().advanced(by: .days(-1))
    )

    let result = await VerifySignupEmail.result(with: .init(token: token), in: context)

    expect(result).toBeError(containing: "already verified")
  }

  func testVerifySignupEmailDoesntChangeAdminUserSubscriptionStatusWhenNotPending() async throws {
    let admin = try await Entities.admin { $0.subscriptionStatus = .trialing } // <-- not pending
    let token = await Current.ephemeral.createAdminIdToken(admin.id)

    let output = try await VerifySignupEmail.resolve(with: .init(token: token), in: context)

    let retrieved = try await Current.db.find(admin.id)

    expect(output.adminId).toEqual(admin.id)
    expect(retrieved.subscriptionStatus).toEqual(.trialing) // <-- not changed
  }

  func testAttemptToLoginWhenEmailNotVerifiedBlocksAndSendsEmail() async throws {
    let admin = try await Entities.admin {
      $0.subscriptionStatus = .pendingEmailVerification
      $0.password = "lol-lol-lol"
    }

    let result = await Login.result(
      with: .init(email: admin.email.rawValue, password: "lol-lol-lol"),
      in: context
    )

    expect(result).toBeError(containing: "until your email is verified")
    expect(sent.postmarkEmails).toHaveCount(1)
    expect(sent.postmarkEmails[0].to).toEqual(admin.email.rawValue)
    expect(sent.postmarkEmails[0].html).toContain("verify your email address")
  }
}
