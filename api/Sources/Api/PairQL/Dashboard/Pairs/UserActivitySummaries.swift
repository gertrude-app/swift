import DuetSQL
import PairQL

struct DateRange: PairNestable, PairInput {
  let start: String
  let end: String
}

struct UserActivitySummaries: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
    let userId: User.Id
    let dateRanges: [DateRange]
  }

  struct Output: PairOutput {
    let userName: String
    let days: [Day]
  }

  struct Day: PairOutput, PairNestable {
    let date: Date
    let numApproved: Int
    let totalItems: Int
  }
}

// resolver

extension UserActivitySummaries: Resolver {
  static func resolve(
    with input: Input,
    in context: AdminContext
  ) async throws -> Output {
    let user = try await context.verifiedUser(from: input.userId)
    let userDeviceIds = try await user.devices(in: context.db).map(\.id)
    let days = try await UserActivitySummaries.days(
      dateRanges: input.dateRanges,
      userDeviceIds: userDeviceIds,
      in: context.db
    )
    return .init(userName: user.name, days: days)
  }

  static func days(
    dateRanges: [DateRange],
    userDeviceIds: [UserDevice.Id],
    in db: any Client
  ) async throws -> [Day] {
    let dates = dateRanges.compactMap(\.dates)
    let earliestStart = dates.map(\.0).min() ?? .distantFuture
    let latestEnd = dates.map(\.1).max() ?? .distantPast

    let screenshots = try await Screenshot.query()
      .where(.userDeviceId |=| userDeviceIds)
      .where(.createdAt <= .date(latestEnd))
      .where(.createdAt > .date(earliestStart))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: db)

    let keystrokes = try await KeystrokeLine.query()
      .where(.userDeviceId |=| userDeviceIds)
      .where(.createdAt <= .date(latestEnd))
      .where(.createdAt > .date(earliestStart))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: db)

    return dates.map {
      let (start, end) = $0
      let screenshots = screenshots.filter {
        $0.createdAt > start && $0.createdAt <= end
      }
      let keystrokeLines = keystrokes.filter {
        $0.createdAt > start && $0.createdAt <= end
      }
      let coalesced = coalesce(screenshots, keystrokeLines)
      let deletedCount = coalesced.lazy.filter(\.isDeleted).count

      return UserActivitySummaries.Day(
        date: start + .hours(12),
        numApproved: deletedCount,
        totalItems: coalesced.count
      )
    }
  }
}

extension DateRange {
  var dates: (Date, Date)? {
    guard let start = try? Date(fromIsoString: start),
          let end = try? Date(fromIsoString: end) else {
      return nil
    }
    return (start, end)
  }
}
