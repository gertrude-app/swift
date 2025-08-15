import Foundation
import GertieIOS
import PairQL
import Tagged
import Vapor

struct UpsertBlockRule: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var id: IOSApp.BlockRule.Id?
    var deviceId: IOSApp.Device.Id
    var rule: GertieIOS.BlockRule
  }

  typealias Output = IOSApp.BlockRule.Id
}

// resolver

extension UpsertBlockRule: Resolver {
  static func resolve(with input: Input, in ctx: ParentContext) async throws -> Output {
    if let id = input.id {
      var blockRule = try await ctx.db.find(id)
      if blockRule.deviceId != input.deviceId {
        throw Abort(.unauthorized)
      }
      blockRule.rule = input.rule
      try await ctx.db.update(blockRule)
      return id
    } else {
      let blockRule = IOSApp.BlockRule(deviceId: input.deviceId, rule: input.rule)
      let rule = try await ctx.db.create(blockRule)
      return rule.id
    }
  }
}

extension IOSApp.BlockRule.Id: @retroactive PairOutput {}
