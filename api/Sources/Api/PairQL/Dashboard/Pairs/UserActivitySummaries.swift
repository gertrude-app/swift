import Dependencies
import DuetSQL
import PairQL

// deprecated, remove 6/14/25
struct UserActivitySummaries: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = Child.Id

  struct Output: PairOutput {
    var userName: String
    var days: [Day]
  }

  struct Day: PairOutput, PairNestable {
    var date: Date
    var numApproved: Int
    var numFlagged: Int
    var numTotal: Int
  }
}

// resolver

extension UserActivitySummaries: Resolver {
  static func resolve(
    with childId: Child.Id,
    in context: AdminContext
  ) async throws -> Output {
    let child = try await context.verifiedUser(from: childId)
    let computerUserIds = try await child.computerUsers(in: context.db).map(\.id)
    let days = try await UserActivitySummaries.days(computerUserIds, in: context.db)
    return .init(userName: child.name, days: days)
  }

  static func days(
    _ computerUserIds: [ComputerUser.Id],
    in db: any Client
  ) async throws -> [Day] {
    @Dependency(\.date) var date

    let twoWeeksAgo = date.now - .days(14)

    let screenshots = try await Screenshot.query()
      .where(.computerUserId |=| computerUserIds)
      .where(.or(
        .createdAt > .date(twoWeeksAgo),
        .isNull(.deletedAt) .&& .not(.isNull(.flagged))
      ))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: db)

    let keystrokes = try await KeystrokeLine.query()
      .where(.computerUserId |=| computerUserIds)
      .where(.or(
        .createdAt > .date(twoWeeksAgo),
        .isNull(.deletedAt) .&& .not(.isNull(.flagged))
      ))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: db)

    var dayMap: [Date: ([Screenshot], [KeystrokeLine])] = [:]

    for screenshot in screenshots {
      let key = Calendar.current.startOfDay(for: screenshot.createdAt)
      if var value = dayMap[key] {
        value.0.append(screenshot)
        dayMap[key] = value
      } else {
        dayMap[key] = ([screenshot], [])
      }
    }

    for keystroke in keystrokes {
      let key = Calendar.current.startOfDay(for: keystroke.createdAt)
      if var value = dayMap[key] {
        value.1.append(keystroke)
        dayMap[key] = value
      } else {
        dayMap[key] = ([], [keystroke])
      }
    }

    var days = dayMap.map { key, value in
      let (screenshots, keystrokes) = value
      let coalesced = coalesce(screenshots, keystrokes)
      let deletedCount = coalesced.lazy.filter(\.isDeleted).count
      let flaggedCount = coalesced.lazy.filter(\.isFlagged).count

      return UserActivitySummaries.Day(
        date: key,
        numApproved: deletedCount,
        numFlagged: flaggedCount,
        numTotal: coalesced.count
      )
    }
    days.sort { $0.date > $1.date }
    return days
  }
}
