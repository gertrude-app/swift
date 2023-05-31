import DuetSQL
import TypescriptPairQL

struct CombinedUsersActivitySummaries: TypescriptPair {
  static var auth: ClientAuth = .admin

  typealias Input = [DateRange]

  struct UserOverview: TypescriptNestable, PairOutput {
    var userId: User.Id
    var userName: String
    var days: [UserActivitySummaries.Day]
  }

  typealias Output = [UserOverview]
}

// resolver

extension CombinedUsersActivitySummaries: Resolver {
  static func resolve(
    with input: Input,
    in context: AdminContext
  ) async throws -> Output {
    let dateRanges = input.compactMap(\.dates)
    let users = try await context.users()
    return try await users.concurrentMap { user in
      let deviceIds = try await user.devices().map(\.id)
      let days = try await dateRanges.concurrentMap { start, end in
        async let screenshots = Current.db.query(Screenshot.self)
          .where(.deviceId |=| deviceIds)
          .where(.createdAt <= .date(end))
          .where(.createdAt > .date(start))
          .orderBy(.createdAt, .desc)
          .withSoftDeleted()
          .all()
        async let keystrokeLines = Current.db.query(KeystrokeLine.self)
          .where(.deviceId |=| deviceIds)
          .where(.createdAt <= .date(end))
          .where(.createdAt > .date(start))
          .orderBy(.createdAt, .desc)
          .withSoftDeleted()
          .all()

        _ = try await (screenshots, keystrokeLines)

        let coalesced = try await coalesce(screenshots, keystrokeLines)
        let deletedCount = coalesced.lazy.filter(\.isDeleted).count

        var day = start
        day.addTimeInterval(.hours(12))

        return UserActivitySummaries.Day(
          date: day,
          numApproved: deletedCount,
          totalItems: coalesced.count
        )
      }
      return UserOverview(userId: user.id, userName: user.name, days: days)
    }
  }
}
