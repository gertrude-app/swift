import DuetSQL
import TypescriptPairQL

struct GetSelectableKeychains: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Keychain: TypescriptNestable {
    let id: Api.Keychain.Id
    let name: String
    let isPublic: Bool
    let authorId: Admin.Id
    let description: String?
    let numKeys: Int
  }

  struct Output: TypescriptPairOutput {
    let own: [Keychain]
    let `public`: [Keychain]
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

// extensions

extension GetSelectableKeychains.Keychain {
  init(from keychain: Api.Keychain) async throws {
    id = keychain.id
    name = keychain.name
    isPublic = keychain.isPublic
    authorId = keychain.authorId
    description = keychain.description
    numKeys = try await Current.db.count(
      Key.self,
      where: .keychainId == keychain.id,
      withSoftDeleted: false
    )
  }
}
