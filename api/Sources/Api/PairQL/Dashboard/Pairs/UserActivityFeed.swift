import DuetSQL
import Foundation
import PairQL
import Vapor

public enum UserActivity {
  public struct Screenshot: PairNestable {
    var id: Api.Screenshot.Id
    var ids: [Api.Screenshot.Id]
    var url: String
    var width: Int
    var height: Int
    var duringSuspension: Bool
    var createdAt: Date
    var deletedAt: Date?
  }

  public struct CoalescedKeystrokeLine: PairNestable {
    var id: KeystrokeLine.Id
    var ids: [KeystrokeLine.Id]
    var appName: String
    var line: String
    var duringSuspension: Bool
    var createdAt: Date
    var deletedAt: Date?
  }

  public enum Item: PairNestable {
    case screenshot(Screenshot)
    case keystrokeLine(CoalescedKeystrokeLine)

    public var screenshot: Screenshot? {
      guard case .screenshot(let screenshot) = self else { return nil }
      return screenshot
    }

    public var keystrokeLine: CoalescedKeystrokeLine? {
      guard case .keystrokeLine(let keystrokeLine) = self else { return nil }
      return keystrokeLine
    }
  }
}

struct UserActivityFeed: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
    var userId: User.Id
    var range: DateRange
  }

  struct Output: PairOutput {
    var userName: String
    var showSuspensionActivity: Bool
    var numDeleted: Int
    var items: [UserActivity.Item]
  }
}

// resolver

extension UserActivityFeed: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    guard let (after, before) = input.range.dates else {
      throw Abort(.badRequest)
    }

    let user = try await context.verifiedUser(from: input.userId)
    let userDeviceIds = try await user.devices(in: context.db).map(\.id)

    async let keystrokes = KeystrokeLine.query()
      .where(.computerUserId |=| userDeviceIds)
      .where(.createdAt <= .date(before))
      .where(.createdAt > .date(after))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: context.db)

    async let screenshots = Screenshot.query()
      .where(.computerUserId |=| userDeviceIds)
      .where(.createdAt <= .date(before))
      .where(.createdAt > .date(after))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: context.db)

    let coalesced = try await coalesce(screenshots, keystrokes)

    return Output(
      userName: user.name,
      showSuspensionActivity: user.showSuspensionActivity,
      numDeleted: coalesced.lazy.filter(\.isDeleted).count,
      items: coalesced.lazy.filter(\.notDeleted)
    )
  }
}

// helpers

func coalesce(
  _ screenshots: [Screenshot],
  _ keystrokes: [KeystrokeLine]
) -> [UserActivity.Item] {
  var sorted: [Either<Screenshot, KeystrokeLine>] =
    screenshots.map(Either.init(_:)) + keystrokes.map(Either.init(_:))
  sorted.sort { $0.createdAt > $1.createdAt }

  var coalesced: [UserActivity.Item] = []
  for item in sorted {
    switch item {
    case .left(let screenshot):
      coalesced.append(.screenshot(.init(from: screenshot)))
    case .right(let keystroke):
      if var coalescedKeystroke = coalesced.last?.keystrokeLine,
         coalescedKeystroke.deletedAt == keystroke.deletedAt,
         keystroke.appName == coalescedKeystroke.appName {
        coalescedKeystroke.line = "\(keystroke.line)\n\(coalescedKeystroke.line)"
        coalescedKeystroke.ids.append(keystroke.id)
        coalescedKeystroke.duringSuspension = coalescedKeystroke.duringSuspension ||
          keystroke.filterSuspended
        coalesced[coalesced.count - 1] = .keystrokeLine(coalescedKeystroke)
      } else {
        coalesced.append(.keystrokeLine(.init(from: keystroke)))
      }
    }
  }

  return coalesced
}

// extensions

extension UserActivity.Item: HasOptionalDeletedAt {
  var deletedAt: Date? {
    get { screenshot?.deletedAt ?? keystrokeLine?.deletedAt }
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
    duringSuspension = screenshot.filterSuspended
    createdAt = screenshot.createdAt
    self.deletedAt = screenshot.deletedAt
  }
}

extension UserActivity.CoalescedKeystrokeLine {
  init(from keystroke: KeystrokeLine) {
    id = keystroke.id
    ids = [keystroke.id]
    appName = keystroke.appName
    line = keystroke.line
    duringSuspension = keystroke.filterSuspended
    createdAt = keystroke.createdAt
    self.deletedAt = keystroke.deletedAt
  }
}
