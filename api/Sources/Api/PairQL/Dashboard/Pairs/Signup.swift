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

  struct Output: PairOutput {
    // relic of waitlist concept, unused, delete if this pair is modified
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

    if email.starts(with: "e2e-test-"), email.contains("@gertrude.app") {
      return Output(url: nil)
    }

    let existing = try? await Current.db.query(Admin.self)
      .where(.email == email)
      .first()

    if existing != nil {
      if Env.mode == .prod {
        Current.sendGrid.fireAndForget(.toJared("Gertrude signup [exists]", email))
      }
      try await Current.postmark.send(accountExists(with: email))
      return .init(url: nil)
    }

    if Env.mode == .prod {
      Current.sendGrid.fireAndForget(.toJared("Gertrude signup", "email: \(email)"))
    }

    let admin = try await Current.db.create(Admin(
      email: .init(rawValue: email),
      password: Env.mode == .test ? input.password : try Bcrypt.hash(input.password),
      subscriptionStatus: .pendingEmailVerification
    ))

    let token = await Current.ephemeral.createAdminIdToken(admin.id)
    try await Current.postmark.send(verify(email, context.dashboardUrl, token))

    return Output(url: nil)
  }
}

// helpers

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
    <a href="\(dashboardUrl)/verify-signup-email/\(token.lowercased)">here</a>.
    """
  )
}
