import Dependencies
import DuetSQL
import XCTest
import XExpect
import XStripe

@testable import Api

final class DasboardUnauthedResolverTests: ApiTestCase {
  let context = Context.mock

  func testInitiateSignupWithBadEmailErrorsBadRequest() async throws {
    let result = await Signup.result(with: .init(email: "💩", password: ""), in: self.context)
    expect(result).toBeError(containing: "Bad Request")
  }

  func testInitiateSignupWithExistingEmailSendsEmail() async throws {
    let existing = try await Current.db.create(Admin.random)

    let input = Signup.Input(email: existing.email.rawValue, password: "pass")
    let output = try await Signup.resolve(with: input, in: self.context)

    expect(output).toEqual(.success)
    expect(sent.postmarkEmails.count).toEqual(1)
    expect(sent.postmarkEmails[0].html).toContain("already has an account")
  }

  func testInitiateSignupHappyPath() async throws {
    Current.date = { .epoch }
    let email = "signup".random + "@example.com"
    let input = Signup.Input(email: email, password: "pass")
    let output = try await Signup.resolve(with: input, in: self.context)

    let admin = try await Current.db.query(Admin.self)
      .where(.email == email)
      .first()

    expect(output).toEqual(.success)
    expect(admin.subscriptionStatus).toEqual(.pendingEmailVerification)
    expect(admin.subscriptionStatusExpiration).toEqual(.epoch.advanced(by: .days(7)))
    expect(sent.postmarkEmails.count).toEqual(1)
    expect(sent.postmarkEmails[0].to).toEqual(email)
    expect(sent.postmarkEmails[0].html).toContain("verify your email address")
  }

  func testInitiateSignupWithGclidAndABVariant() async throws {
    let email = "signup".random + "@example.com"
    let input = Signup.Input(
      email: email,
      password: "pass",
      gclid: "gclid-123",
      abTestVariant: "old_site"
    )

    _ = try await Signup.resolve(with: input, in: self.context)

    let admin = try await Current.db.query(Admin.self)
      .where(.email == email)
      .first()

    expect(admin.gclid).toEqual("gclid-123")
    expect(admin.abTestVariant).toEqual("old_site")
  }

  func testLoginFromMagicLink() async throws {
    let admin = try await Current.db.create(Admin.random)
    let uuids = MockUUIDs()

    let output = try await withDependencies {
      $0.uuid = .mock(uuids)
    } operation: {
      let token = await Current.ephemeral.createAdminIdToken(admin.id)
      return try await LoginMagicLink.resolve(with: .init(token: token), in: self.context)
    }

    let adminToken = try await Current.db.find(AdminToken.Id(uuids[1]))
    expect(output).toEqual(.init(token: .init(uuids[2]), adminId: admin.id))
    expect(adminToken.value).toEqual(.init(uuids[2]))
    expect(adminToken.adminId).toEqual(admin.id)
  }

  func testRequestMagicLink() async throws {
    let admin = try await Current.db.create(Admin.random)

    let (token, output) = try await withUUID {
      try await RequestMagicLink.resolve(
        with: .init(email: admin.email.rawValue, redirect: nil),
        in: .init(requestId: "", dashboardUrl: "/dash", ipAddress: nil)
      )
    }

    expect(output).toEqual(.success)
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails.first!.text).toContain("href='/dash/otp/\(token.lowercased)'")
    expect(sent.emails.first!.text).not.toContain("redirect=")
  }

  func testSendMagicLinkWithRedirect() async throws {
    let admin = try await Current.db.create(Admin.random)

    let (token, output) = try await withUUID {
      try await RequestMagicLink.resolve(
        with: .init(email: admin.email.rawValue, redirect: "/foo"),
        in: .init(requestId: "", dashboardUrl: "/dash", ipAddress: nil)
      )
    }

    expect(output).toEqual(.success)
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails.first!.text).toContain("/otp/\(token.lowercased)?redirect=%2Ffoo")
  }

  func testSendMagicLinkToUnknownEmailReturnsSuccessSendingNoAccountEmail() async throws {
    let output = try await RequestMagicLink.resolve(
      with: .init(email: "some@hacker.com", redirect: nil),
      in: self.context
    )

    expect(output).toEqual(.success)
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails.first!.text).toContain("no Gertrude account exists")
  }
}
