import Foundation
import PairQL
import Vapor

struct ConfirmPendingNotificationMethod: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let id: AdminVerifiedNotificationMethod.Id
    let code: Int
  }
}

// extensions

extension ConfirmPendingNotificationMethod: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let method = await with(dependency: \.ephemeral)
      .confirmPendingNotificationMethod(input.id, input.code)
    guard let method else {
      throw Abort(.unauthorized, reason: "[@client:incorrectConfirmationCode]")
    }
    guard method.parentId == context.admin.id else {
      throw Abort(.unauthorized)
    }
    try await context.db.create(method)
    return .success
  }
}
