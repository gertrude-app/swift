import DuetSQL
import TypescriptPairQL
import Vapor

struct CombinedUsersActivityFeed: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    var range: DateRange
  }

  struct UserDay: TypescriptPairOutput {
    var userName: String
    var numDeleted: Int
    var items: [Union2<UserActivity.Screenshot, UserActivity.CoalescedKeystrokeLine>]
  }

  typealias Output = [UserDay]
}

// resolver

extension CombinedUsersActivityFeed: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    guard let (after, before) = input.range.dates else {
      throw Abort(.badRequest)
    }

    let users = try await context.users()

    return try await users.concurrentMap { user in
      let deviceIds = try await user.devices().map(\.id)
      async let keystrokes = Current.db.query(KeystrokeLine.self)
        .where(.deviceId |=| deviceIds)
        .where(.createdAt <= .date(before))
        .where(.createdAt > .date(after))
        .orderBy(.createdAt, .desc)
        .withSoftDeleted()
        .all()

      async let screenshots = Current.db.query(Screenshot.self)
        .where(.deviceId |=| deviceIds)
        .where(.createdAt <= .date(before))
        .where(.createdAt > .date(after))
        .orderBy(.createdAt, .desc)
        .withSoftDeleted()
        .all()

      let coalesced = try await coalesce(screenshots, keystrokes)

      return UserDay(
        userName: user.name,
        numDeleted: coalesced.lazy.filter(\.isDeleted).count,
        items: coalesced.lazy.filter(\.notDeleted)
      )
    }
  }
}
