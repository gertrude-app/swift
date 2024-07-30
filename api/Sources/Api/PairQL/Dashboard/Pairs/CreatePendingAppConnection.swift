import Foundation
import PairQL

struct CreatePendingAppConnection: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
    var userId: User.Id
  }

  struct Output: PairOutput {
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
