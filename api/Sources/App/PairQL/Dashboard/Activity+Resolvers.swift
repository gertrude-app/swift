import DashboardRoute
import DuetSQL

extension GetUserActivityDays: PairResolver {
  static func resolve(
    for input: Input,
    in context: AdminContext
  ) async throws -> Output {
    let user = try await context.verifiedUser(from: input.userId)
    let dateRanges = input.dateRanges.compactMap(\.dates)
    let deviceIds = try await user.devices().map(\.id)

    let days = try await withThrowingTaskGroup(
      of: GetUserActivityDays.Day.self
    ) { group -> [GetUserActivityDays.Day] in
      for (start, end) in dateRanges {
        group.addTask {
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
          fatalError()

          // let coalesced = try await coalesce(screenshots, keystrokeLines)
          // let deletedCount = coalesced.lazy.filter(\.isDeleted).count

          // return AppSchema.MonitoringRangeCounts(
          //   dateRange: .init(start: start.isoString, end: end.isoString),
          //   notDeletedCount: coalesced.count - deletedCount,
          //   deletedCount: deletedCount
          // )
        }
      }
      var days: [GetUserActivityDays.Day] = []
      for try await rangeCount in group {
        days.append(rangeCount)
      }
      return days
    }

    return .init(userName: user.name, days: days)
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
