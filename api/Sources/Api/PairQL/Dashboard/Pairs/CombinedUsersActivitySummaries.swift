import DuetSQL
import PairQL

struct CombinedUsersActivitySummaries: Pair {
  static let auth: ClientAuth = .admin
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
    let userDeviceIds = try await context.userDevices().map(\.id)
    return try await dateRanges.concurrentMap { start, end in
      async let screenshots = Screenshot.query()
        .where(.userDeviceId |=| userDeviceIds)
        .where(.createdAt <= .date(end))
        .where(.createdAt > .date(start))
        .orderBy(.createdAt, .desc)
        .withSoftDeleted()
        .all()
      async let keystrokeLines = KeystrokeLine.query()
        .where(.userDeviceId |=| userDeviceIds)
        .where(.createdAt <= .date(end))
        .where(.createdAt > .date(start))
        .orderBy(.createdAt, .desc)
        .withSoftDeleted()
        .all()

      _ = try await (screenshots, keystrokeLines)

      let coalesced = try await coalesce(screenshots, keystrokeLines)
      let deletedCount = coalesced.lazy.filter(\.isDeleted).count

      return UserActivitySummaries.Day(
        date: start + .hours(12),
        numApproved: deletedCount,
        totalItems: coalesced.count
      )
    }
  }
}
