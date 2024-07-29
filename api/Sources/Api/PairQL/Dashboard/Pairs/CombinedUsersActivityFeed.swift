import DuetSQL
import PairQL
import Vapor

struct CombinedUsersActivityFeed: Pair {
  static let auth: ClientAuth = .admin

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

    let users = try await context.users()

    return try await users.concurrentMap { user in
      let userDeviceIds = try await user.devices().map(\.id)
      async let keystrokes = Current.db.query(KeystrokeLine.self)
        .where(.userDeviceId |=| userDeviceIds)
        .where(.createdAt <= .date(before))
        .where(.createdAt > .date(after))
        .orderBy(.createdAt, .desc)
        .withSoftDeleted()
        .all()

      async let screenshots = Current.db.query(Screenshot.self)
        .where(.userDeviceId |=| userDeviceIds)
        .where(.createdAt <= .date(before))
        .where(.createdAt > .date(after))
        .orderBy(.createdAt, .desc)
        .withSoftDeleted()
        .all()

      let coalesced = try await coalesce(screenshots, keystrokes)

      return UserDay(
        userName: user.name,
        showSuspensionActivity: user.showSuspensionActivity,
        numDeleted: coalesced.lazy.filter(\.isDeleted).count,
        items: coalesced.lazy.filter(\.notDeleted)
      )
    }
  }
}
