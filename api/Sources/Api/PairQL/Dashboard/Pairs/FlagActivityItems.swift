import Dependencies
import DuetSQL
import Foundation
import PairQL
import Vapor

struct FlagActivityItems: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = [UUID]
}

extension FlagActivityItems: Resolver {
  static func resolve(with ids: [UUID], in ctx: AdminContext) async throws -> Output {
    @Dependency(\.date.now) var now

    var screenshots = try await Screenshot.query()
      .where(.id |=| ids.map { .uuid($0) })
      .all(in: ctx.db)
    for i in 0 ..< screenshots.count {
      screenshots[i].flagged = screenshots[i].flagged == nil ? now : nil
    }
    if !screenshots.isEmpty {
      try await ctx.db.update(screenshots)
      return .success // dash never sends a mix of screenshots and keystrokes
    }

    var keystrokes = try await KeystrokeLine.query()
      .where(.id |=| ids.map { .uuid($0) })
      .all(in: ctx.db)
    for i in 0 ..< keystrokes.count {
      keystrokes[i].flagged = keystrokes[i].flagged == nil ? now : nil
    }
    if !keystrokes.isEmpty {
      try await ctx.db.update(keystrokes)
      return .success
    }

    throw Abort(.notFound)
  }
}
