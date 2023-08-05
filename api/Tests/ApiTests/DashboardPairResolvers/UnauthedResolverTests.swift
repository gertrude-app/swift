import DuetMock
import DuetSQL
import XCTest
import XExpect
import XStripe

@testable import Api

final class DasboardUnauthedResolverTests: ApiTestCase {
  let context = Context.mock

  func testInitiateSignupWithBadEmailErrorsBadRequest() async throws {
    let result = await Signup.result(with: .init(email: "💩", password: ""), in: context)
    expect(result).toBeError(containing: "Bad Request")
  }

  func testInitiateSignupWithExistingEmailSendsEmail() async throws {
    let existing = try await Current.db.create(Admin.random)

    let input = Signup.Input(email: existing.email.rawValue, password: "pass")
    let output = try await Signup.resolve(with: input, in: context)

    expect(output).toEqual(.success)
    expect(sent.postmarkEmails.count).toEqual(1)
    expect(sent.postmarkEmails[0].html).toContain("already has an account")
  }

  func testInitiateSignupHappyPath() async throws {
    let email = "signup".random + "@example.com"
    let input = Signup.Input(email: email, password: "pass")
    let output = try await Signup.resolve(with: input, in: context)

    let user = try await Current.db.query(Admin.self)
      .where(.email == email)
      .first()

    expect(output).toEqual(.success)
    expect(user.subscriptionStatus).toEqual(.pendingEmailVerification)
    expect(sent.postmarkEmails.count).toEqual(1)
    expect(sent.postmarkEmails[0].to).toEqual(email)
    expect(sent.postmarkEmails[0].html).toContain("verify your email address")
  }

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

  func testLoginFromMagicLink() async throws {
    let admin = try await Current.db.create(Admin.random)
    let token = await Current.ephemeral.createAdminIdToken(admin.id)
    let (tokenId, tokenValue) = mockUUIDs()

    let output = try await LoginMagicLink.resolve(with: .init(token: token), in: context)

    let adminToken = try await Current.db.find(AdminToken.Id(tokenId))
    expect(output).toEqual(.init(token: .init(tokenValue), adminId: admin.id))
    expect(adminToken.value).toEqual(.init(tokenValue))
    expect(adminToken.adminId).toEqual(admin.id)
  }

  func testRequestMagicLink() async throws {
    let admin = try await Current.db.create(Admin.random)
    let (token, _) = mockUUIDs()

    let output = try await RequestMagicLink.resolve(
      with: .init(email: admin.email.rawValue, redirect: nil),
      in: .init(requestId: "", dashboardUrl: "/dash")
    )

    expect(output).toEqual(.success)
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails.first!.text).toContain("href='/dash/otp/\(token.lowercased)'")
    expect(sent.emails.first!.text).not.toContain("redirect=")
  }

  func testSendMagicLinkWithRedirect() async throws {
    let admin = try await Current.db.create(Admin.random)
    let (token, _) = mockUUIDs()

    let output = try await RequestMagicLink.resolve(
      with: .init(email: admin.email.rawValue, redirect: "/foo"),
      in: .init(requestId: "", dashboardUrl: "/dash")
    )

    expect(output).toEqual(.success)
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails.first!.text).toContain("/otp/\(token.lowercased)?redirect=%2Ffoo")
  }

  func testSendMagicLinkToUnknownEmailReturnsSuccessSendingNoAccountEmail() async throws {
    let output = try await RequestMagicLink.resolve(
      with: .init(email: "some@hacker.com", redirect: nil),
      in: context
    )

    expect(output).toEqual(.success)
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails.first!.text).toContain("no Gertrude account exists")
  }
}
