import DuetSQL
import PairQL

struct GetUnlockRequests: Pair {
  static let auth: ClientAuth = .parent
  typealias Output = [GetUnlockRequest.Output]
}

// resolver

extension GetUnlockRequests: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    let users = try await Child.query()
      .where(.parentId == context.parent.id)
      .all(in: context.db)
    let computerUsers = try await ComputerUser.query()
      .where(.childId |=| users.map { .id($0) })
      .all(in: context.db)
    let requests = try await UnlockRequest.query()
      .where(.computerUserId |=| computerUsers.map { .id($0) })
      .all(in: context.db)

    // TODO: this is super inefficient, re-queries for same entities...
    return try await requests.concurrentMap { try await .init(from: $0, in: context) }
  }
}
