import DashboardRoute
import DuetSQL
import Vapor
import XStripe

extension GetCheckoutUrl: PairResolver {
  static func resolve(
    for input: Input,
    in context: DashboardContext
  ) async throws -> Output {
    let admin = try await Current.db.find(Admin.Id(input.adminId))

    let sessionData = Stripe.CheckoutSessionData(
      successUrl: "\(context.dashboardUrl)/checkout-success?session_id={CHECKOUT_SESSION_ID}",
      cancelUrl: "\(context.dashboardUrl)/checkout-cancel?session_id={CHECKOUT_SESSION_ID}",
      lineItems: [.init(quantity: 1, priceId: Env.STRIPE_SUBSCRIPTION_PRICE_ID)],
      mode: .subscription,
      clientReferenceId: admin.id.lowercased,
      customerEmail: admin.email.rawValue,
      trialPeriodDays: 60,
      // following params allow for no credit card required
      trialEndBehavior: .createInvoice,
      paymentMethodCollection: .ifRequired
    )

    let session = try await Current.stripe.createCheckoutSession(sessionData)
    guard let url = session.url else {
      // TODO: logger
      // Current.logger.error("created stripe checkout session, but received no url")
      throw Abort(.internalServerError)
    }

    return .init(url: url)
  }
}

extension Signup: PairResolver {
  static func resolve(
    for input: Input,
    in context: DashboardContext
  ) async throws -> Output {
    let email = input.email.lowercased()
    if !email.isValidEmail {
      throw Abort(.badRequest)
    }

    if Env.mode == .prod {
      Current.sendGrid.fireAndForget(.toJared("Gertrude signup", "email: \(email)"))
    }

    // ------ FUTURE ME --------
    // if the input has a .signupToken, check it against the waitlisted_users table
    // if we find it, create an admin with a pre-verified email, and send
    // back stripe payment url. the web dashboard should redirect, skipping email verification
    // -------------------------

    let existing = try? await Current.db.query(Admin.self)
      .where(.email == email)
      .first()

    if existing != nil {
      try await Current.sendGrid.send(accountExists(with: email))
      return .init(url: nil)
    }

    let admin = try await Current.db.create(Admin(
      email: .init(rawValue: email),
      password: try Bcrypt.hash(input.password),
      subscriptionStatus: .pendingEmailVerification
    ))

    let token = await Current.ephemeral.createMagicLinkToken(admin.id)
    try await Current.sendGrid.send(verify(email, context.dashboardUrl, token))

    return .init(url: nil)
  }
}

extension VerifySignupEmail: PairResolver {
  static func resolve(
    for input: Input,
    in context: DashboardContext
  ) async throws -> Output {
    guard let adminId = await Current.ephemeral.adminIdFromMagicLinkToken(input.token) else {
      throw Abort(.notFound)
    }

    let admin = try await Current.db.find(adminId)
    if admin.subscriptionStatus != .pendingEmailVerification {
      return .init(adminId: admin.id.rawValue)
    }

    admin.subscriptionStatus = .emailVerified
    try await Current.db.update(admin)
    // they get a default "verified" notification method, since they verified their email
    try await Current.db.create(AdminVerifiedNotificationMethod(
      adminId: admin.id,
      method: .email(email: admin.email.rawValue)
    ))
    return .init(adminId: admin.id.rawValue)
  }
}

extension JoinWaitlist: PairResolver {
  static func resolve(
    for input: Input,
    in context: DashboardContext
  ) async throws -> Output {
    let email = input.email.lowercased()
    guard email.isValidEmail else {
      throw Abort(.badRequest)
    }

    let waitlisted = WaitlistedAdmin(email: .init(email))
    let existing = try? await Current.db.query(WaitlistedAdmin.self)
      .where(.email == .string(waitlisted.email.rawValue))
      .first()
    if existing != nil { return .true }

    if Env.mode == .prod {
      Current.sendGrid.fireAndForget(.toJared("Gertrude waitlist", "email: \(email)"))
    }

    try await Current.db.create(waitlisted)
    return .true
  }
}

extension AllowingSignups: NoInputPairResolver {
  static func resolve(in context: DashboardContext) async throws -> Output {
    let allowedPerDay = Current.env.get("NUM_ALLOWED_SIGNUPS_PER_DAY").flatMap { Int($0) } ?? 1
    let todaysSignups = try await Current.db.query(Admin.self)
      .where(
        .subscriptionStatus |!=| [
          Admin.SubscriptionStatus.pendingEmailVerification,
          Admin.SubscriptionStatus.emailVerified,
        ]
      )
      .where(.createdAt >= .date(Calendar.current.startOfDay(for: Date())))
      .all()
    return .init(todaysSignups.count < allowedPerDay)
  }
}

// helpers

private func accountExists(with email: String) -> Email {
  Email.fromApp(
    to: email,
    subject: "Gertrude Signup Request",
    html: "We received a request to initiate a signup for the Gertrude app, but this email address already has an account! Try signing in instead."
  )
}

private func verify(_ email: String, _ dashboardUrl: String, _ token: UUID) -> Email {
  Email.fromApp(
    to: email,
    subject: "Verify your email to start using Gertrude",
    html: """
    Please verify your email address by clicking <a href="\(dashboardUrl)/verify-signup-email/\(token
      .lowercased)">here</a>.
    """
  )
}
