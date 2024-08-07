import PairQL
import Vapor

struct LoginMagicLink: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    var token: UUID
  }

  typealias Output = AdminAuth
}

// resolver

extension LoginMagicLink: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    guard let adminId = await Current.ephemeral.unexpiredAdminIdFromToken(input.token) else {
      throw context.error(
        "9a314d21",
        .unauthorized,
        "Magic link token invalid or expired",
        .magicLinkTokenNotFound
      )
    }
    let token = try await Current.db.create(AdminToken(adminId: adminId))
    return Output(token: token.value, adminId: adminId)
  }
}
