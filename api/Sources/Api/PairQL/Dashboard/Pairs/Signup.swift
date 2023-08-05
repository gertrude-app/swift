import DuetSQL
import Foundation
import PairQL
import Vapor
import XPostmark

struct Signup: Pair {
  static var auth: ClientAuth = .none

  struct Input: PairInput {
    var email: String
    var password: String
  }
}

// resolver

extension Signup: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let email = input.email.lowercased()
    if !email.isValidEmail {
      throw Abort(.badRequest)
    }

    let existing = try? await Current.db.query(Admin.self)
      .where(.email == email)
      .first()

    if existing != nil {
      if Env.mode == .prod {
        Current.sendGrid.fireAndForget(.toJared("signup [exists]", email))
      }
      try await Current.postmark.send(accountExists(with: email))
      return .success
    }

    if Env.mode == .prod {
      Current.sendGrid.fireAndForget(.toJared("signup", "email: \(email)"))
    }

    let admin = try await Current.db.create(Admin(
      email: .init(rawValue: email),
      password: Env.mode == .test ? input.password : try Bcrypt.hash(input.password),
      subscriptionStatus: .pendingEmailVerification
    ))

    try await sendVerificationEmail(to: admin, in: context)
    return .success
  }
}

// helpers

func sendVerificationEmail(to admin: Admin, in context: Context) async throws {
  let token = await Current.ephemeral.createAdminIdToken(
    admin.id,
    expiration: Current.date().advanced(by: .hours(24))
  )

  try await Current.postmark.send(verify(admin.email.rawValue, context.dashboardUrl, token))
}

private func accountExists(with email: String) -> XPostmark.Email {
  .init(
    to: email,
    from: "noreply@gertrude.app",
    subject: "Gertrude Signup Request".withEmailSubjectDisambiguator,
    html: """
    We received a request to initiate a signup for the Gertrude app, \
    but this email address already has an account! Try signing in instead.\
    <br /><br />
    Or, if you just created your account, check your spam folder for the verification email.
    """
  )
}

private func verify(_ email: String, _ dashboardUrl: String, _ token: UUID) -> XPostmark.Email {
  .init(
    to: email,
    from: "noreply@gertrude.app",
    subject: "Action Required: Confirm your email".withEmailSubjectDisambiguator,
    html: """
    Please verify your email address by clicking \
    <a href="\(dashboardUrl)/verify-signup-email/\(token.lowercased)">here</a>.\
    <br /><br />
    This link will expire in 24 hours.
    """
  )
}
