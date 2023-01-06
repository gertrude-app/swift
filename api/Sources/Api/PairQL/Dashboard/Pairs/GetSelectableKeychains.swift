import DuetSQL
import TypescriptPairQL

struct GetSelectableKeychains: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Output: TypescriptPairOutput {
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
      .all()
    return try await .init(
      own: own.concurrentMap { try await .init(from: $0) },
      public: `public`.concurrentMap { try await .init(from: $0) }
    )
  }
}
