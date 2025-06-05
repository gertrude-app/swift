import PairQL

struct GetUsers: Pair {
  static let auth: ClientAuth = .parent
  typealias Output = [GetUser.User]
}

// resolvers

extension GetUsers: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    let users = try await context.parent.children(in: context.db)
    return try await users.concurrentMap { try await .init(from: $0, in: context.db) }
  }
}
