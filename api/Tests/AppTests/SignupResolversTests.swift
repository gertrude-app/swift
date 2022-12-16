import DashboardRoute
import DuetSQL
import XCTest
import XExpect

@testable import App

final class SignupResolversTests: AppTestCase {
  let context = DashboardContext(dashboardUrl: "/")

  func testAllowingSignupsReturnsFalseWhenExceedingNumAllowed() async throws {
    Current.env = .init(get: { _ in "0" })
    let output = try await AllowingSignups.resolve(in: context)
    expect(output).toEqual(.false)
  }

  func testAllowingSignupsReturnsTrueWhenSignupsLessThanMax() async throws {
    Current.env = .init(get: { _ in "10000000" })
    let output = try await AllowingSignups.resolve(in: context)
    expect(output).toEqual(.true)
  }

  func testInitiateSignupWithBadEmailErrorsBadRequest() async throws {
    let result = await Signup.result(for: .init(email: "💩", password: ""), in: context)
    expect(result).toBeError(containing: "Bad Request")
  }

  func testInitiateSignupWithExistingEmailSendsEmail() async throws {
    let existing = try await Current.db.create(Admin.random)

    let input = Signup.Input(email: existing.email.rawValue, password: "pass")
    let output = try await Signup.resolve(for: input, in: context)

    expect(output).toEqual(.init(url: nil))
    expect(sent.emails.count).toEqual(1)
    expect(sent.emails[0].text).toContain("already has an account")
  }

  func testInitiateSignupHappyPath() async throws {
    let email = "signup".random + "@example.com"
    let input = Signup.Input(email: email, password: "pass")
    let output = try await Signup.resolve(for: input, in: context)

    let user = try await Current.db.query(Admin.self)
      .where(.email == email)
      .first()

    expect(output).toEqual(.init(url: nil))
    expect(user.subscriptionStatus).toEqual(.pendingEmailVerification)
    expect(sent.emails.count).toEqual(1)
    expect(sent.emails[0].firstRecipient.email).toEqual(email)
    expect(sent.emails[0].text).toContain("verify your email address")
  }

  func testVerifySignupEmailSetsSubsriptionStatusAndCreatesNotificationMethod() async throws {
    let admin = try await Entities.admin { $0.subscriptionStatus = .pendingEmailVerification }
    let token = await Current.ephemeral.createMagicLinkToken(admin.id)

    let output = try await VerifySignupEmail.resolve(for: .init(token: token), in: context)

    let retrieved = try await Current.db.find(admin.id)
    let method = try await Current.db.query(AdminVerifiedNotificationMethod.self)
      .where(.adminId == admin.id)
      .first()

    expect(output).toEqual(.init(adminId: admin.id.rawValue))
    expect(retrieved.subscriptionStatus).toEqual(.emailVerified)
    expect(method.method).toEqual(.email(email: admin.email.rawValue))
  }

  func testVerifySignupEmailDoesntChangeAdminUserSubscriptionStatusWhenNotPending() async throws {
    let admin = try await Entities.admin { $0.subscriptionStatus = .trialing } // <-- not pending
    let token = await Current.ephemeral.createMagicLinkToken(admin.id)

    let output = try await VerifySignupEmail.resolve(for: .init(token: token), in: context)

    let retrieved = try await Current.db.find(admin.id)

    expect(output).toEqual(.init(adminId: admin.id.rawValue))
    expect(retrieved.subscriptionStatus).toEqual(.trialing) // <-- not changed
  }
}
