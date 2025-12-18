import DuetSQL
import PairQL
import Vapor
import XSlack

struct VerifyAdminMagicLink: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    var token: UUID
  }

  struct Output: PairOutput {
    var token: UUID
  }
}

extension VerifyAdminMagicLink: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    guard let email = await with(dependency: \.ephemeral)
      .unexpiredSuperAdminEmailFromToken(input.token) else {
      throw context.error(
        "9b314d21",
        .unauthorized,
        "Magic link token invalid or expired",
      )
    }

    let adminToken = try await context.db.create(SuperAdminToken())
    await with(dependency: \.slack).internal(.info, "Super admin logged in: \(email)")
    return .init(token: adminToken.value.rawValue)
  }
}
