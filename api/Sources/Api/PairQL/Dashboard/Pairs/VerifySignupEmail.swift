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
    switch await Current.ephemeral.adminIdFromToken(input.token) {

    // happy path: verification is successful
    case .notExpired(let adminId):
      var admin = try await context.db.find(adminId)
      let token = try await context.db.create(AdminToken(adminId: admin.id))
      if admin.subscriptionStatus != .pendingEmailVerification {
        return .init(token: token.value, adminId: admin.id)
      }

      admin.subscriptionStatus = .trialing
      admin.subscriptionStatusExpiration = Current.date().advanced(by: .days(60 - 7))

      try await context.db.update(admin)

      // they get a default "verified" notification method, since they verified their email
      try await context.db.create(AdminVerifiedNotificationMethod(
        adminId: admin.id,
        config: .email(email: admin.email.rawValue)
      ))

      if context.env.mode == .prod, !isTestAddress(admin.email.rawValue) {
        Current.sendGrid.fireAndForget(.toJared("email verified", admin.email.rawValue))
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
