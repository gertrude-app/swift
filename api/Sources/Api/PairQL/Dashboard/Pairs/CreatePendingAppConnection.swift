import Foundation
import PairQL

struct CreatePendingAppConnection: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var userId: Child.Id
  }

  struct Output: PairOutput {
    var code: Int
  }
}

// resolver

extension CreatePendingAppConnection: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let user = try await context.verifiedChild(from: input.userId)
    let code = await with(dependency: \.ephemeral)
      .createPendingAppConnection(user.id)
    return Output(code: code)
  }
}
