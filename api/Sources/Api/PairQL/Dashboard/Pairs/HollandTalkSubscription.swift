import PairQL
import Vapor

struct HollandTalkSubscription: Pair {
  static var auth: ClientAuth = .none

  struct Input: PairInput {
    var email: String
  }
}

// resolver

extension HollandTalkSubscription: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    throw Abort(.notImplemented)
  }
}
