import Foundation
import PairQL
import Vapor

struct ResetPassword: Pair {
  static var auth: ClientAuth = .none

  struct Input: PairInput {
    var token: UUID
    var password: String
  }
}

// resolver

extension ResetPassword: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    if let adminId = await Current.ephemeral.adminIdFromToken(input.token) {
      let admin = try await Current.db.find(adminId)
      admin.password = try Bcrypt.hash(input.password)
      try await Current.db.update(admin)
      return .success
    } else {
      return .failure
    }
  }
}
