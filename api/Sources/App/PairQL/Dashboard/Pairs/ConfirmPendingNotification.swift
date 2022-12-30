import Foundation
import TypescriptPairQL
import Vapor

struct ConfirmPendingNotificationMethod: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    let id: AdminVerifiedNotificationMethod.Id
    let code: Int
  }
}

// extensions

extension ConfirmPendingNotificationMethod: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let method = await Current.ephemeral.confirmPendingNotificationMethod(input.id, input.code)
    guard let method = method else {
      throw Abort(.unauthorized, reason: "[@client:incorrectConfirmationCode]")
    }
    guard method.adminId == context.admin.id else {
      throw Abort(.unauthorized)
    }
    try await Current.db.create(method)
    return .success
  }
}
