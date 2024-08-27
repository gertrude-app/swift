import MacAppRoute

extension CreateUnlockRequests_v2: Resolver {
  static func resolve(
    with input: Input,
    in context: UserContext
  ) async throws -> Output {
    _ = try await CreateUnlockRequests_v3.resolve(with: input, in: context)
    return .success
  }
}
