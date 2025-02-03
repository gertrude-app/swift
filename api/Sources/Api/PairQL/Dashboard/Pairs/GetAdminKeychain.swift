import DuetSQL
import PairQL

struct GetAdminKeychain: Pair {
  static let auth: ClientAuth = .admin
  typealias Input = Keychain.Id
  typealias Output = GetAdminKeychains.AdminKeychain
}

// resolver

extension GetAdminKeychain: Resolver {
  static func resolve(
    with id: Keychain.Id,
    in context: AdminContext
  ) async throws -> Output {
    let model = try await Keychain.query()
      .where(.id == id)
      .where(.parentId == context.admin.id)
      .first(in: context.db)

    return try await Output(from: model, in: context)
  }
}
