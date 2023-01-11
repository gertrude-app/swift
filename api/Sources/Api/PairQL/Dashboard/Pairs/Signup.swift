import DuetSQL
import Foundation
import TypescriptPairQL
import Vapor

struct Signup: TypescriptPair {
  static var auth: ClientAuth = .none

  struct Input: TypescriptPairInput {
    var email: String
    var password: String
    var signupToken: String?
  }

  struct Output: TypescriptPairOutput {
    let url: String?
  }
}

// resolver

extension Signup: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
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
      password: Env.mode == .test ? input.password : try Bcrypt.hash(input.password),
      subscriptionStatus: .pendingEmailVerification
    ))

    let token = await Current.ephemeral.createMagicLinkToken(admin.id)
    try await Current.sendGrid.send(verify(email, context.dashboardUrl, token))

    return Output(url: nil)
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
