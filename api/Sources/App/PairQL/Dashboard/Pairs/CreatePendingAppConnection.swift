import Foundation
import TypescriptPairQL

struct CreatePendingAppConnection: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    var userId: UUID
  }

  struct Output: TypescriptPairOutput {
    var code: Int
  }
}

// resolver

extension CreatePendingAppConnection: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let user = try await context.verifiedUser(from: input.userId)
    let code = await Current.ephemeral.createPendingAppConnection(user.id)
    return Output(code: code)
  }
}
