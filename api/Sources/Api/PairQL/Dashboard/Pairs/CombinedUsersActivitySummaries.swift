import DuetSQL
import PairQL

struct CombinedUsersActivitySummaries: Pair {
  static let auth: ClientAuth = .admin
  typealias Output = [UserActivitySummaries.Day]
}

// resolver

extension CombinedUsersActivitySummaries: NoInputResolver {
  static func resolve(in ctx: AdminContext) async throws -> Output {
    let computerUserIds = try await ctx.userDevices().map(\.id)
    return try await UserActivitySummaries.days(computerUserIds, in: ctx.db)
  }
}
