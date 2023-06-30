import DuetMock
import DuetSQL
import XCTest
import XExpect
import XStripe

@testable import Api

final class DasboardUnauthedResolverTests: ApiTestCase {
  let context = Context.mock

  func testAllowingSignupsReturnsFalseWhenExceedingNumAllowed() async throws {
    Current.env = .init(get: { _ in "0" })
    let output = try await AllowingSignups.resolve(in: context)
    expect(output).toEqual(.failure)
  }

  func testAllowingSignupsReturnsTrueWhenSignupsLessThanMax() async throws {
    Current.env = .init(get: { _ in "10000000" })
    let output = try await AllowingSignups.resolve(in: context)
    expect(output).toEqual(.success)
  }

  func testInitiateSignupWithBadEmailErrorsBadRequest() async throws {
    let result = await Signup.result(with: .init(email: "💩", password: ""), in: context)
    expect(result).toBeError(containing: "Bad Request")
  }

  func testInitiateSignupWithExistingEmailSendsEmail() async throws {
    let existing = try await Current.db.create(Admin.random)

    let input = Signup.Input(email: existing.email.rawValue, password: "pass")
    let output = try await Signup.resolve(with: input, in: context)

    expect(output).toEqual(.init(url: nil))
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

    expect(output).toEqual(.init(url: nil))
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

    expect(output).toEqual(.init(adminId: admin.id))
    expect(retrieved.subscriptionStatus).toEqual(.emailVerified)
    expect(method.config).toEqual(.email(email: admin.email.rawValue))
  }

  func testVerifySignupEmailDoesntChangeAdminUserSubscriptionStatusWhenNotPending() async throws {
    let admin = try await Entities.admin { $0.subscriptionStatus = .trialing } // <-- not pending
    let token = await Current.ephemeral.createAdminIdToken(admin.id)

    let output = try await VerifySignupEmail.resolve(with: .init(token: token), in: context)

    let retrieved = try await Current.db.find(admin.id)

    expect(output).toEqual(.init(adminId: admin.id))
    expect(retrieved.subscriptionStatus).toEqual(.trialing) // <-- not changed
  }

  func testGetCheckoutUrl() async throws {
    var sessionData: Stripe.CheckoutSessionData?
    Current.stripe.createCheckoutSession = { data in
      sessionData = data
      return .init(id: "cs_123", url: "result-url", subscription: nil, clientReferenceId: nil)
    }

    let admin = try await Current.db.create(Admin.random)
    let output = try await GetCheckoutUrl.resolve(
      with: .init(adminId: admin.id),
      in: context
    )

    expect(output).toEqual(.init(url: "result-url"))

    expect(sessionData).toEqual(.init(
      successUrl: "//checkout-success?session_id={CHECKOUT_SESSION_ID}",
      cancelUrl: "//checkout-cancel?session_id={CHECKOUT_SESSION_ID}",
      lineItems: [.init(quantity: 1, priceId: Env.STRIPE_SUBSCRIPTION_PRICE_ID)],
      mode: .subscription,
      clientReferenceId: admin.id.lowercased,
      customerEmail: admin.email.rawValue,
      trialPeriodDays: 60,
      trialEndBehavior: .createInvoice,
      paymentMethodCollection: .ifRequired
    ))
  }

  func testHandleCheckoutSuccess() async throws {
    let sessionId = "cs_123"
    let admin = try await Current.db.create(Admin.random)
    let (_, tokenValue) = mockUUIDs()

    Current.stripe.getCheckoutSession = { id in
      expect(id).toBe(sessionId)
      return .init(
        id: "cs_123",
        url: nil,
        subscription: "sub_123",
        clientReferenceId: admin.id.lowercased
      )
    }

    Current.stripe.getSubscription = { id in
      expect(id).toBe("sub_123")
      return .init(id: id, status: .trialing, customer: "cus_123")
    }

    let output = try await HandleCheckoutSuccess.resolve(
      with: .init(stripeCheckoutSessionId: sessionId),
      in: context
    )

    let retrieved = try await Current.db.find(admin.id)
    expect(output).toEqual(.init(token: .init(tokenValue), adminId: admin.id))
    expect(retrieved.subscriptionId).toEqual(.init(rawValue: "sub_123"))
    expect(retrieved.subscriptionStatus).toEqual(.trialing)
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

  func testSendMagicLinkToUnknownEmailReturnsSuccessEmittingNoEvent() async throws {
    let output = try await RequestMagicLink.resolve(
      with: .init(email: "some@hacker.com", redirect: nil),
      in: context
    )

    expect(output).toEqual(.success)
    expect(sent.emails).toBeEmpty()
  }
}
