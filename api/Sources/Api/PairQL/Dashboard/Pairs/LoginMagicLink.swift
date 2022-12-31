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
  static func resolve(
    with input: Input,
    in context: DashboardContext
  ) async throws -> Output {
    guard let adminId = await Current.ephemeral.adminIdFromMagicLinkToken(input.token) else {
      throw Abort(.notFound)
    }
    let token = try await Current.db.create(AdminToken(adminId: adminId))
    return Output(token: token.value, adminId: adminId)
  }
}
