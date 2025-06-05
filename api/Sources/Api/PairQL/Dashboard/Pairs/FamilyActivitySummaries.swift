import DuetSQL
import PairQL

struct FamilyActivitySummaries: Pair {
  static let auth: ClientAuth = .parent
  struct Input: PairInput {
    var jsTimezoneOffsetMinutes: Int
  }

  typealias Output = [ChildActivitySummaries.Day]
}

// resolver

extension FamilyActivitySummaries: Resolver {
  static func resolve(with input: Input, in ctx: ParentContext) async throws -> Output {
    let computerUserIds = try await ctx.computerUsers().map(\.id)
    return try await ChildActivitySummaries.days(
      computerUserIds,
      input.jsTimezoneOffsetMinutes,
      in: ctx.db
    )
  }
}
