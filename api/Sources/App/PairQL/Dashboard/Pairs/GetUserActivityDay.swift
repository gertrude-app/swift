import DuetSQL
import Foundation
import TypescriptPairQL
import Vapor

public enum UserActivity {
  public struct Screenshot: TypescriptNestable {
    var id: UUID
    var ids: [UUID]
    var url: String
    var width: Int
    var height: Int
    var createdAt: Date
  }

  public struct CoalescedKeystrokeLine: TypescriptNestable {
    var id: UUID
    var ids: [UUID]
    var appName: String
    var line: String
    var createdAt: Date
  }
}

struct GetUserActivityDay: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    var userId: UUID
    var range: DateRange
  }

  struct Output: TypescriptPairOutput {
    var userName: String
    var items: [Union2<UserActivity.Screenshot, UserActivity.CoalescedKeystrokeLine>]
  }
}

// resolver

extension GetUserActivityDay: Resolver {
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
      .all()

    async let screenshots = Current.db.query(Screenshot.self)
      .where(.deviceId |=| deviceIds)
      .where(.createdAt <= .date(before))
      .where(.createdAt > .date(after))
      .all()

    let coalesced = try await coalesce(screenshots, keystrokes)
    return Output(userName: user.name, items: coalesced)
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
      coalesced.append(.a(.init(from: screenshot)))
    case .right(let keystroke):
      if var coalescedKeystroke = coalesced.last?.b,
         keystroke.appName == coalescedKeystroke.appName {
        coalescedKeystroke.line = "\(keystroke.line)\n\(coalescedKeystroke.line)"
        coalescedKeystroke.ids.append(keystroke.id.rawValue)
        coalesced[coalesced.count - 1] = .b(coalescedKeystroke)
      } else {
        coalesced.append(.b(.init(from: keystroke)))
      }
    }
  }

  return coalesced
}

// extensions

extension Union2: NamedUnion where
  A == UserActivity.Screenshot,
  B == UserActivity.CoalescedKeystrokeLine {
  public static var __typeName: String { "Item" }
}

extension UserActivity.Screenshot {
  init(from screenshot: Screenshot) {
    id = screenshot.id.rawValue
    ids = [screenshot.id.rawValue]
    url = screenshot.url
    width = screenshot.width
    height = screenshot.height
    createdAt = screenshot.createdAt
  }
}

extension UserActivity.CoalescedKeystrokeLine {
  init(from keystroke: KeystrokeLine) {
    id = keystroke.id.rawValue
    ids = [keystroke.id.rawValue]
    appName = keystroke.appName
    line = keystroke.line
    createdAt = keystroke.createdAt
  }
}
