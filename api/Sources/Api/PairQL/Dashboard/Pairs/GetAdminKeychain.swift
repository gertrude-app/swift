import DuetSQL
import PairQL

struct GetAdminKeychain: Pair {
  static var auth: ClientAuth = .admin
  typealias Input = Keychain.Id
  typealias Output = GetAdminKeychains.AdminKeychain
}

// resolver

extension GetAdminKeychain: Resolver {
  static func resolve(
    with id: Keychain.Id,
    in context: AdminContext
  ) async throws -> Output {
    let model = try await Current.db.query(Keychain.self)
      .where(.id == id)
      .where(.authorId == context.admin.id)
      .first()

    return try await Output(from: model, in: context)
  }
}
