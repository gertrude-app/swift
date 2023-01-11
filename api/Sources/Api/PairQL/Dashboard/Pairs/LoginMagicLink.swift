import TypescriptPairQL
import Vapor

struct LoginMagicLink: TypescriptPair {
  static var auth: ClientAuth = .none

  struct Input: TypescriptPairInput {
    var token: UUID
  }

  typealias Output = AdminAuth
}

// resolver

extension LoginMagicLink: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    guard let adminId = await Current.ephemeral.adminIdFromMagicLinkToken(input.token) else {
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
