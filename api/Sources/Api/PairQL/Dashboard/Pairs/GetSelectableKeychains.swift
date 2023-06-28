import DuetSQL
import PairQL

struct GetSelectableKeychains: Pair {
  static var auth: ClientAuth = .admin

  struct Output: PairOutput {
    let own: [KeychainSummary]
    let `public`: [KeychainSummary]
  }
}

// resolver

extension GetSelectableKeychains: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    async let own = context.admin.keychains()
    async let `public` = Current.db.query(Api.Keychain.self)
      .where(.isPublic == true)
      .where(.authorId != context.admin.id)
      .all()
    return try await .init(
      own: own.concurrentMap { try await .init(from: $0) },
      public: `public`.concurrentMap { try await .init(from: $0) }
    )
  }
}
