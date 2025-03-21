import Dependencies
import Foundation
import PairQL
import Vapor

struct AdminAuth: PairOutput {
  var token: AdminToken.Value
  var adminId: Admin.Id
}

struct VerifySignupEmail: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let token: UUID
  }

  typealias Output = AdminAuth
}

// resolver

extension VerifySignupEmail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    switch await with(dependency: \.ephemeral).adminIdFromToken(input.token) {

    // happy path: verification is successful
    case .notExpired(let adminId):
      var admin = try await context.db.find(adminId)
      let token = try await context.db.create(AdminToken(parentId: admin.id))
      if admin.subscriptionStatus != .pendingEmailVerification {
        return .init(token: token.value, adminId: admin.id)
      }

      admin.subscriptionStatusExpiration = get(dependency: \.date.now) + .days(21 - 3)
      admin.subscriptionStatus = .trialing

      try await context.db.update(admin)

      // they get a default "verified" notification method, since they verified email
      try await context.db.create(AdminVerifiedNotificationMethod(
        parentId: admin.id,
        config: .email(email: admin.email.rawValue)
      ))

      if context.env.mode == .prod, !isTestAddress(admin.email.rawValue) {
        with(dependency: \.postmark)
          .toSuperAdmin("signup completed", admin.email.rawValue)
        await with(dependency: \.slack)
          .internal(.signups, "email verified: `\(admin.email.rawValue)`")
      }

      return Output(token: token.value, adminId: admin.id)

    case .notFound:
      throw Abort(.notFound)

    case .expired(let adminId):
      let admin = try await context.db.find(adminId)
      if admin.subscriptionStatus == .pendingEmailVerification {
        try await sendVerificationEmail(to: admin, in: context)
        throw context.error("84a6c609", .badRequest, user: EXPIRED_TOKEN_MSG)
      } else {
        throw context.error(
          "beb1b493",
          .badRequest,
          "email already verified",
          .emailAlreadyVerified
        )
      }

    case .previouslyRetrieved(let adminId):
      let admin = try await context.db.find(adminId)
      if admin.subscriptionStatus == .pendingEmailVerification {
        try await sendVerificationEmail(to: admin, in: context)
        throw context.error("6257bfb9", .badRequest, user: UNEXPECTED_RESEND_MSG)
      } else {
        throw context.error(
          "f2b70e49",
          .badRequest,
          "email already verified",
          .emailAlreadyVerified
        )
      }
    }
  }
}

// helpers

private let EXPIRED_TOKEN_MSG =
  "The link you clicked has expired, but we sent a new verification email. Please check your email and try again."

private let UNEXPECTED_RESEND_MSG =
  "Sorry, we couldn't verify you this time, but we sent a new verification email. Please check your email and try again."
