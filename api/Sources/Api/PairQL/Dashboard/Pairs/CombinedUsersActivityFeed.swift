import DuetSQL
import PairQL
import Vapor

struct CombinedUsersActivityFeed: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var range: DateRange
  }

  struct UserDay: PairOutput {
    var userName: String
    var showSuspensionActivity: Bool
    var numDeleted: Int
    var items: [UserActivity.Item]
  }

  typealias Output = [UserDay]
}

// resolver

extension CombinedUsersActivityFeed: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    guard let (after, before) = input.range.dates else {
      throw Abort(.badRequest)
    }

    let children = try await context.children()

    return try await children.concurrentMap { child in
      let computerUserIds = try await child.computerUsers(in: context.db).map(\.id)

      async let keystrokes = KeystrokeLine.query()
        .where(.computerUserId |=| computerUserIds)
        .where(.createdAt <= .date(before))
        .where(.createdAt > .date(after))
        .orderBy(.createdAt, .desc)
        .withSoftDeleted()
        .all(in: context.db)

      async let screenshots = Screenshot.query()
        .where(.computerUserId |=| computerUserIds)
        .where(.createdAt <= .date(before))
        .where(.createdAt > .date(after))
        .orderBy(.createdAt, .desc)
        .withSoftDeleted()
        .all(in: context.db)

      let coalesced = try await coalesce(screenshots, keystrokes)

      return UserDay(
        userName: child.name,
        showSuspensionActivity: child.showSuspensionActivity,
        numDeleted: coalesced.lazy.filter(\.isDeleted).count,
        items: coalesced.lazy.filter(\.notDeleted)
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
