import Dependencies
import DuetSQL
import PairQL

struct KeychainSummary: PairNestable {
  var id: Api.Keychain.Id
  var parentId: Parent.Id
  var name: String
  var description: String?
  var warning: String?
  var isPublic: Bool
  var numKeys: Int
}

struct GetSelectableKeychains: Pair {
  static let auth: ClientAuth = .parent

  struct Output: PairOutput {
    var own: [KeychainSummary]
    var `public`: [KeychainSummary]
  }
}

// resolver

extension GetSelectableKeychains: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    async let own = context.parent.keychains(in: context.db)
    async let `public` = Keychain.query()
      .where(.isPublic == true)
      .where(.parentId != context.parent.id)
      .all(in: context.db)
    return try await .init(
      own: own.concurrentMap { try await .init(from: $0) },
      public: `public`.concurrentMap { try await .init(from: $0) }
    )
  }
}

extension KeychainSummary {
  init(from keychain: Keychain) async throws {
    @Dependency(\.db) var db
    let numKeys = try await db.count(Key.self, where: .keychainId == keychain.id)
    self.init(
      id: keychain.id,
      parentId: keychain.parentId,
      name: keychain.name,
      description: keychain.description,
      warning: keychain.warning,
      isPublic: keychain.isPublic,
      numKeys: numKeys
    )
  }
}
