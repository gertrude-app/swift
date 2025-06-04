import Dependencies
import DuetSQL
import PairQL

struct ChildActivitySummaries: Pair {
  static let auth: ClientAuth = .parent
  struct Input: PairInput {
    var childId: Child.Id
    var jsTimezoneOffsetMinutes: Int
  }

  struct Output: PairOutput {
    var childName: String
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

extension ChildActivitySummaries: Resolver {
  static func resolve(
    with input: Input,
    in context: AdminContext
  ) async throws -> Output {
    let child = try await context.verifiedUser(from: input.childId)
    let computerUserIds = try await child.computerUsers(in: context.db).map(\.id)
    let days = try await ChildActivitySummaries.days(
      computerUserIds,
      input.jsTimezoneOffsetMinutes,
      in: context.db
    )
    return .init(childName: child.name, days: days)
  }

  static func days(
    _ computerUserIds: [ComputerUser.Id],
    _ jsTimezoneOffsetMinutes: Int,
    in db: any Client
  ) async throws -> [Day] {
    @Dependency(\.date) var date

    let twoWeeksAgo = date.now - .days(14)
    var calendar = Calendar.current
    // NB: js returns timezone offsets as minutes BEHIND UTC, hence negative
    if let jsTz = TimeZone(secondsFromGMT: -jsTimezoneOffsetMinutes * 60) {
      calendar.timeZone = jsTz
    }

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
      let key = calendar.startOfDay(for: screenshot.createdAt)
      if var value = dayMap[key] {
        value.0.append(screenshot)
        dayMap[key] = value
      } else {
        dayMap[key] = ([screenshot], [])
      }
    }

    for keystroke in keystrokes {
      let key = calendar.startOfDay(for: keystroke.createdAt)
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

      return ChildActivitySummaries.Day(
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
