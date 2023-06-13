import DuetSQL
import TypescriptPairQL

struct CombinedUsersActivitySummaries: TypescriptPair {
  static var auth: ClientAuth = .admin
  typealias Input = [DateRange]
  typealias Output = [UserActivitySummaries.Day]
}

// resolver

extension CombinedUsersActivitySummaries: Resolver {
  static func resolve(
    with input: Input,
    in context: AdminContext
  ) async throws -> Output {
    let dateRanges = input.compactMap(\.dates)
    let deviceIds = try await context.userDevices().map(\.id)
    return try await dateRanges.concurrentMap { start, end in
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
  }
}
