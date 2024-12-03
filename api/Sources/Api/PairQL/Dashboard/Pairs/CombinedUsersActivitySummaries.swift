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
    let earliestStart = dateRanges.map(\.0).min() ?? .distantFuture
    let latestEnd = dateRanges.map(\.1).max() ?? .distantPast
    let userDeviceIds = try await context.userDevices().map(\.id)

    let screenshots = try await Screenshot.query()
      .where(.userDeviceId |=| userDeviceIds)
      .where(.createdAt <= .date(latestEnd))
      .where(.createdAt > .date(earliestStart))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: context.db)

    let keystrokes = try await KeystrokeLine.query()
      .where(.userDeviceId |=| userDeviceIds)
      .where(.createdAt <= .date(latestEnd))
      .where(.createdAt > .date(earliestStart))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: context.db)

    return dateRanges.map {
      let (start, end) = $0
      let screenshots = screenshots.filter {
        $0.createdAt > start && $0.createdAt <= end
      }
      let keystrokeLines = keystrokes.filter {
        $0.createdAt > start && $0.createdAt <= end
      }
      let coalesced = coalesce(screenshots, keystrokeLines)
      let deletedCount = coalesced.lazy.filter(\.isDeleted).count
      return .init(
        date: start + .hours(12),
        numApproved: deletedCount,
        totalItems: coalesced.count
      )
    }
  }
}
