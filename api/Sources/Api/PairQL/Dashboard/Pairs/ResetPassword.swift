import Foundation
import PairQL
import Vapor

struct ResetPassword: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    var token: UUID
    var password: String
  }
}

// resolver

extension ResetPassword: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    if let parentId = await with(dependency: \.ephemeral)
      .unexpiredParentIdFromToken(input.token) {
      var parent = try await context.db.find(parentId)
      parent.password = try Bcrypt.hash(input.password)
      try await context.db.update(parent)
      dashSecurityEvent(.passwordChanged, parent: parent.id, in: context)
      return .success
    } else {
      return .failure
    }
  }
}
