import DuetSQL
import PairQL

struct GetAdminKeychain: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = Keychain.Id

  struct Output: PairNestable, PairOutput {
    let summary: KeychainSummary
    let keys: [GetAdminKeychains.Key]
  }
}

// resolver

extension GetAdminKeychain: Resolver {
  static func resolve(
    with id: Keychain.Id,
    in context: ParentContext
  ) async throws -> Output {
    let model = try await Keychain.query()
      .where(.id == id)
      .where(.parentId == context.parent.id)
      .first(in: context.db)

    return try await Output(from: model, in: context)
  }
}

extension GetAdminKeychain.Output {
  init(from model: Api.Keychain, in context: ParentContext) async throws {
    let keys = try await model.keys(in: context.db)
    try await self.init(
      summary: .init(from: model),
      keys: keys.map { .init(from: $0, keychainId: model.id) }
    )
  }
}
