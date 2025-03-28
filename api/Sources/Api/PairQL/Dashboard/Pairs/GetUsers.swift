import PairQL

struct GetUsers: Pair {
  static let auth: ClientAuth = .parent
  typealias Output = [GetUser.User]
}

// resolvers

extension GetUsers: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let users = try await context.admin.users(in: context.db)
    return try await users.concurrentMap { try await .init(from: $0, in: context.db) }
  }
}
