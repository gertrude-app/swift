import Dependencies
import DuetSQL
import Foundation
import PairQL
import Vapor
import XPostmark

struct Signup: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    var email: String
    var password: String
    var gclid: String?
    var abTestVariant: String?
  }

  struct Output: PairOutput {
    var admin: Login.Output?
  }
}

// resolver

extension Signup: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    @Dependency(\.date.now) var now
    @Dependency(\.postmark) var postmark

    let email = input.email.lowercased()
    if !email.isValidEmail {
      throw Abort(.badRequest)
    }

    let existing = try? await Admin.query()
      .where(.email == email)
      .first(in: context.db)

    if let existing {
      if !existing.isPendingEmailVerification, let creds = try? await Login.resolve(
        with: .init(email: input.email, password: input.password),
        in: context
      ) {
        return .init(admin: creds)
      }

      if context.env.mode == .prod, !isTestAddress(email) {
        postmark.toSuperAdmin("signup [exists]", email)
      }

      if existing.isPendingEmailVerification {
        try await sendVerificationEmail(to: existing, in: context)
      } else {
        try await postmark.send(accountExists(with: email, context.dashboardUrl))
      }

      return .init(admin: nil)
    }

    if context.env.mode == .prod, !isTestAddress(email) {
      postmark.toSuperAdmin(
        "signup",
        [
          "email: \(email)",
          "g-ad: \(input.gclid != nil)",
          "A/B: \(input.abTestVariant ?? "(nil)")",
        ].joined(separator: "<br />")
      )
    }

    let admin = try await context.db.create(Admin(
      email: .init(rawValue: email),
      password: context.env.mode == .test ? input.password : try Bcrypt.hash(input.password),
      subscriptionStatus: .pendingEmailVerification,
      subscriptionStatusExpiration: now + .days(7),
      gclid: input.gclid,
      abTestVariant: input.abTestVariant
    ))

    try await sendVerificationEmail(to: admin, in: context)
    return .init(admin: nil)
  }
}

// helpers

func sendVerificationEmail(to admin: Admin, in context: Context) async throws {
  let token = await with(dependency: \.ephemeral)
    .createAdminIdToken(
      admin.id,
      expiration: get(dependency: \.date.now) + .hours(24)
    )

  try await with(dependency: \.postmark)
    .send(verify(admin.email.rawValue, context.dashboardUrl, token))
}

private func accountExists(with email: String, _ dashboardUrl: String) -> XPostmark.Email {
  .init(
    to: email,
    from: "Gertrude App <noreply@gertrude.app>",
    subject: "Gertrude Signup Request".withEmailSubjectDisambiguator,
    html: """
    We received a request to initiate a signup for the Gertrude app, \
    but this email address already has an account! \
    Try <a href="\(dashboardUrl)/login">logging in</a> instead.
    """
  )
}

private func verify(_ email: String, _ dashboardUrl: String, _ token: UUID) -> XPostmark.Email {
  .init(
    to: email,
    from: "Gertrude App <noreply@gertrude.app>",
    subject: "Action Required: Confirm your email".withEmailSubjectDisambiguator,
    html: """
    Please verify your email address by clicking \
    <a href="\(dashboardUrl)/verify-signup-email/\(token.lowercased)">here</a>.\
    <br /><br />
    This link will expire in 24 hours.
    """
  )
}
