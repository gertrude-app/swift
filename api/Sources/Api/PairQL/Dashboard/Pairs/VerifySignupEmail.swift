import Foundation
import PairQL
import Vapor

struct AdminAuth: PairOutput {
  var token: AdminToken.Value
  var adminId: Admin.Id
}

struct VerifySignupEmail: Pair {
  static var auth: ClientAuth = .none

  struct Input: PairInput {
    let token: UUID
  }

  typealias Output = AdminAuth
}

// resolver

extension VerifySignupEmail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    guard let adminId = await Current.ephemeral.adminIdFromToken(input.token) else {
      throw Abort(.notFound)
    }

    let admin = try await Current.db.find(adminId)
    let token = try await Current.db.create(AdminToken(adminId: admin.id))
    if admin.subscriptionStatus != .pendingEmailVerification {
      return .init(token: token.value, adminId: admin.id)
    }

    admin.subscriptionStatus = .trialing
    try await admin.save()

    // they get a default "verified" notification method, since they verified their email
    try await Current.db.create(AdminVerifiedNotificationMethod(
      adminId: admin.id,
      config: .email(email: admin.email.rawValue)
    ))

    if Env.mode == .prod {
      Current.sendGrid.fireAndForget(.toJared("email verified", admin.email.rawValue))
    }

    return Output(token: token.value, adminId: admin.id)
  }
}
