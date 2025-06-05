import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class SignupTests: ApiTestCase, @unchecked Sendable {
  let context = Context.mock

  func testInitiateSignupWithBadEmailErrorsBadRequest() async throws {
    let result = await Signup.result(with: .init(email: "💩", password: ""), in: self.context)
    expect(result).toBeError(containing: "Bad Request")
  }

  func testInitiateSignupWithExistingVerifiedEmailButBadPasswordSendsEmail() async throws {
    let existing = try await self.db.create(Parent.random {
      $0.password = "nope"
      $0.subscriptionStatus = .trialing
    })

    let input = Signup.Input(email: existing.email.rawValue, password: "pass")
    let output = try await Signup.resolve(with: input, in: self.context)

    expect(output).toEqual(.init(admin: nil))
    expect(sent.emails.count).toEqual(1)
    expect(sent.emails[0].template).toBe("re-signup")
  }

  func testInitiateSignupHappyPath() async throws {
    let email = "signup".random + "@example.com"
    let input = Signup.Input(email: email, password: "pass")
    let output = try await Signup.resolve(with: input, in: self.context)

    let parent = try await Parent.query()
      .where(.email == email)
      .first(in: self.db)

    expect(output).toEqual(.init(admin: nil))
    expect(parent.subscriptionStatus).toEqual(.pendingEmailVerification)
    expect(parent.subscriptionStatusExpiration).toEqual(.reference.advanced(by: .days(7)))
    expect(sent.emails.count).toEqual(1)
    expect(sent.emails[0].to).toEqual(email)
    expect(sent.emails[0].template).toBe("initial-signup")
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

    let parent = try await Parent.query()
      .where(.email == email)
      .first(in: self.db)

    expect(parent.gclid).toEqual("gclid-123")
    expect(parent.abTestVariant).toEqual("old_site")
  }

  func testSigningUpWhenAlreadyVerifiedReturnsAuthCreds() async throws {
    let uuids = MockUUIDs()
    let existing = try await self.parent {
      $0.subscriptionStatus = .trialing
      $0.password = "pass"
    }

    try await withDependencies {
      $0.uuid = .mock(uuids)
    } operation: {
      let input = Signup.Input(email: existing.email.rawValue, password: "pass")
      let output = try await Signup.resolve(with: input, in: self.context)

      expect(output).toEqual(.init(admin: .init(
        adminId: existing.id,
        token: .init(uuids[1])
      )))

      expect(sent.emails.count).toEqual(0)
    }
  }
}
