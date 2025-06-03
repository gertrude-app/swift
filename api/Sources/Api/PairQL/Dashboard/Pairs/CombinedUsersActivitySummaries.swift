import DuetSQL
import PairQL

// deprecated, remove 6/14/25
struct CombinedUsersActivitySummaries: Pair {
  static let auth: ClientAuth = .parent
  typealias Output = [UserActivitySummaries.Day]
}

// resolver

extension CombinedUsersActivitySummaries: NoInputResolver {
  static func resolve(in ctx: AdminContext) async throws -> Output {
    let computerUserIds = try await ctx.computerUsers().map(\.id)
    return try await UserActivitySummaries.days(computerUserIds, in: ctx.db)
  }
}
