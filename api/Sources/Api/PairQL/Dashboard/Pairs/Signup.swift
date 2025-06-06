import Dependencies
import DuetSQL
import Foundation
import PairQL
import Vapor

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
    @Dependency(\.slack) var slack

    let email = input.email.lowercased()
    if !email.isValidEmail {
      throw Abort(.badRequest)
    }

    let existing = try? await Parent.query()
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
        try await postmark.send(template: .reSignup(
          to: email,
          model: .init(dashboardUrl: context.dashboardUrl)
        ))
      }

      return .init(admin: nil)
    }

    let parent = try await context.db.create(Parent(
      email: .init(rawValue: email),
      password: context.env.mode == .test ? input.password : Bcrypt.hash(input.password),
      subscriptionStatus: .pendingEmailVerification,
      subscriptionStatusExpiration: now + .days(7),
      gclid: input.gclid,
      abTestVariant: input.abTestVariant
    ))

    if context.env.mode == .prod, !isTestAddress(email) {
      await slack.internal(.signups, """
        *New signup:*
        id: `\(parent.id.lowercased)`
        email: `\(email)`
        g-ad: `\(input.gclid != nil)`
      """)
    }

    try await sendVerificationEmail(to: parent, in: context)
    return .init(admin: nil)
  }
}

// helpers

func sendVerificationEmail(to admin: Parent, in context: Context) async throws {
  let token = await with(dependency: \.ephemeral)
    .createParentIdToken(
      admin.id,
      expiration: get(dependency: \.date.now) + .hours(24)
    )

  try await with(dependency: \.postmark)
    .send(template: .initialSignup(
      to: admin.email.rawValue,
      model: .init(dashboardUrl: context.dashboardUrl, token: token)
    ))
}
