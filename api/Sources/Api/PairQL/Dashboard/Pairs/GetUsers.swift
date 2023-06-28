import PairQL

struct GetUsers: Pair {
  static var auth: ClientAuth = .admin
  typealias Output = [GetUser.User]
}

// resolvers

extension GetUsers: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let users = try await context.admin.users()
    return try await users.concurrentMap { try await .init(from: $0) }
  }
}
