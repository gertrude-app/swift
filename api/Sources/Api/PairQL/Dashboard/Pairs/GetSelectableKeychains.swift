import DuetSQL
import PairQL

struct GetSelectableKeychains: Pair {
  static let auth: ClientAuth = .admin

  struct Output: PairOutput {
    let own: [KeychainSummary]
    let `public`: [KeychainSummary]
  }
}

// resolver

extension GetSelectableKeychains: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    async let own = context.admin.keychains(in: context.db)
    async let `public` = Api.Keychain.query()
      .where(.isPublic == true)
      .where(.authorId != context.admin.id)
      .all(in: context.db)
    return try await .init(
      own: own.concurrentMap { try await .init(from: $0) },
      public: `public`.concurrentMap { try await .init(from: $0) }
    )
  }
}
