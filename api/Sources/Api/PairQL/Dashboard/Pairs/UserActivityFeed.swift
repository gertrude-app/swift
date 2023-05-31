import DuetSQL
import Foundation
import TypescriptPairQL
import Vapor

public enum UserActivity {
  public struct Screenshot: TypescriptNestable {
    var id: Api.Screenshot.Id
    var ids: [Api.Screenshot.Id]
    var url: String
    var width: Int
    var height: Int
    var createdAt: Date
    var deletedAt: Date?
  }

  public struct CoalescedKeystrokeLine: TypescriptNestable {
    var id: KeystrokeLine.Id
    var ids: [KeystrokeLine.Id]
    var appName: String
    var line: String
    var createdAt: Date
    var deletedAt: Date?
  }
}

struct UserActivityFeed: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    var userId: User.Id
    var range: DateRange
  }

  struct Output: TypescriptPairOutput {
    var userName: String
    var numDeleted: Int
    var items: [Union2<UserActivity.Screenshot, UserActivity.CoalescedKeystrokeLine>]
  }
}

// resolver

extension UserActivityFeed: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    guard let (after, before) = input.range.dates else {
      throw Abort(.badRequest)
    }

    let user = try await context.verifiedUser(from: input.userId)
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

    return Output(
      userName: user.name,
      numDeleted: coalesced.lazy.filter(\.isDeleted).count,
      items: coalesced.lazy.filter(\.notDeleted)
    )
  }
}

// helpers

func coalesce(
  _ screenshots: [Screenshot],
  _ keystrokes: [KeystrokeLine]
) -> [Union2<UserActivity.Screenshot, UserActivity.CoalescedKeystrokeLine>] {
  var sorted: [Either<Screenshot, KeystrokeLine>] =
    screenshots.map(Either.init(_:)) + keystrokes.map(Either.init(_:))
  sorted.sort { $0.createdAt > $1.createdAt }

  var coalesced: [Union2<UserActivity.Screenshot, UserActivity.CoalescedKeystrokeLine>] = []
  for item in sorted {
    switch item {
    case .left(let screenshot):
      coalesced.append(.t1(.init(from: screenshot)))
    case .right(let keystroke):
      if var coalescedKeystroke = coalesced.last?.t2,
         coalescedKeystroke.deletedAt == keystroke.deletedAt,
         keystroke.appName == coalescedKeystroke.appName {
        coalescedKeystroke.line = "\(keystroke.line)\n\(coalescedKeystroke.line)"
        coalescedKeystroke.ids.append(keystroke.id)
        coalesced[coalesced.count - 1] = .t2(coalescedKeystroke)
      } else {
        coalesced.append(.t2(.init(from: keystroke)))
      }
    }
  }

  return coalesced
}

// extensions

extension Union2: NamedType where
  T1 == UserActivity.Screenshot,
  T2 == UserActivity.CoalescedKeystrokeLine {
  public static var __typeName: String { "Item" }
}

extension Union2: HasOptionalDeletedAt where
  T1 == UserActivity.Screenshot,
  T2 == UserActivity.CoalescedKeystrokeLine {
  var deletedAt: Date? {
    get { t1?.deletedAt ?? t2?.deletedAt }
    set {}
  }
}

extension UserActivity.Screenshot {
  init(from screenshot: Screenshot) {
    id = screenshot.id
    ids = [screenshot.id]
    url = screenshot.url
    width = screenshot.width
    height = screenshot.height
    createdAt = screenshot.createdAt
    deletedAt = screenshot.deletedAt
  }
}

extension UserActivity.CoalescedKeystrokeLine {
  init(from keystroke: KeystrokeLine) {
    id = keystroke.id
    ids = [keystroke.id]
    appName = keystroke.appName
    line = keystroke.line
    createdAt = keystroke.createdAt
    deletedAt = keystroke.deletedAt
  }
}
