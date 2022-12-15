import DashboardRoute
import DuetSQL
import Vapor
import XCTest

@testable import App

extension PairResolver {
  static func result(for input: Input, in context: Context) async -> Result<Output, Error> {
    do {
      return .success(try await resolve(for: input, in: context))
    } catch {
      return .failure(error)
    }
  }
}

final class SignupResolversTests: AppTestCase {
  let context = DashboardContext(dashboardUrl: "/")

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
}
