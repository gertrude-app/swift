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
    guard let parentId = await with(dependency: \.ephemeral)
      .unexpiredParentIdFromToken(input.token) else {
      throw context.error(
        "9a314d21",
        .unauthorized,
        "Magic link token invalid or expired",
        .magicLinkTokenNotFound
      )
    }

    dashSecurityEvent(.login, "using magic link", parent: parentId, in: context)
    let token = try await context.db.create(Parent.DashToken(parentId: parentId))
    return Output(token: token.value, adminId: parentId)
  }
}
