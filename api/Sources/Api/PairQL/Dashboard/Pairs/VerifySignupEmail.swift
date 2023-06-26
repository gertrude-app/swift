import Foundation
import PairQL
import Vapor

struct VerifySignupEmail: Pair {
  static var auth: ClientAuth = .none

  struct Input: PairInput {
    let token: UUID
  }

  struct Output: PairOutput {
    let adminId: Admin.Id
  }
}

// resolver

extension VerifySignupEmail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    guard let adminId = await Current.ephemeral.adminIdFromToken(input.token) else {
      throw Abort(.notFound)
    }

    let admin = try await Current.db.find(adminId)
    if admin.subscriptionStatus != .pendingEmailVerification {
      return .init(adminId: admin.id)
    }

    admin.subscriptionStatus = .emailVerified
    try await Current.db.update(admin)
    // they get a default "verified" notification method, since they verified their email
    try await Current.db.create(AdminVerifiedNotificationMethod(
      adminId: admin.id,
      config: .email(email: admin.email.rawValue)
    ))
    return Output(adminId: admin.id)
  }
}
