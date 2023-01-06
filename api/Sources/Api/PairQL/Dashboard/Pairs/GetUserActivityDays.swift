import DuetSQL
import TypescriptPairQL

struct DateRange: TypescriptNestable {
  let start: String
  let end: String
}

struct GetUserActivityDays: Pair, TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    let userId: User.Id
    let dateRanges: [DateRange]
  }

  struct Output: TypescriptPairOutput {
    let userName: String
    let days: [Day]
  }

  struct Day: TypescriptNestable {
    let date: Date
    let numApproved: Int
    let totalItems: Int
  }
}

// resolver

extension GetUserActivityDays: Resolver {
  static func resolve(
    with input: Input,
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

          let coalesced = try await coalesce(screenshots, keystrokeLines)
          let deletedCount = coalesced.lazy.filter(\.isDeleted).count

          var day = start
          day.addTimeInterval(.hours(12))

          return .init(
            date: day,
            numApproved: deletedCount,
            totalItems: coalesced.count
          )
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
