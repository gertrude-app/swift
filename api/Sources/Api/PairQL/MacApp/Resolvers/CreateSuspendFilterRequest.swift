import MacAppRoute
import Vapor

extension CreateSuspendFilterRequest: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    _ = try await CreateSuspendFilterRequest_v2.resolve(with: input, in: context)
    return .success
  }
}
