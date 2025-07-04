import Foundation
import Gertie
import GertieIOS
import PairQL

struct GetIOSDevice: Pair {
  static let auth: ClientAuth = .parent

  typealias Input = IOSApp.Device.Id

  struct Output: PairOutput {
    struct BlockGroup: PairNestable {
      var id: IOSApp.BlockGroup.Id
      var name: String
    }

    struct BlockRuleData: PairOutput {
      var id: IOSApp.BlockRule.Id
      var rule: GertieIOS.BlockRule
    }

    var childName: String
    var deviceType: String
    var osVersion: String
    var allBlockGroups: [BlockGroup]
    var enabledBlockGroups: [IOSApp.BlockGroup.Id]
    var webPolicy: WebContentFilterPolicy.Kind
    var webPolicyDomains: [String]
    var customBlockRules: [BlockRuleData]
  }
}

extension GetIOSDevice: Resolver {
  static func resolve(
    with id: IOSApp.Device.Id,
    in ctx: ParentContext
  ) async throws -> Output {
    let device = try await ctx.db.find(id)
    let child = try await device.child(in: ctx.db)
    let enabledBlockGroups = try await device.blockGroups(in: ctx.db)
    let allBlockGroups = try await IOSApp.BlockGroup.query().all(in: ctx.db)
    let domains = try await device.webPolicyDomains(in: ctx.db)
    let blockRules = try await device.blockRules(in: ctx.db)
    return .init(
      childName: child.name,
      deviceType: device.deviceType,
      osVersion: device.iosVersion,
      allBlockGroups: allBlockGroups.map { .init(id: $0.id, name: $0.name) },
      enabledBlockGroups: enabledBlockGroups.map(\.id),
      webPolicy: .init(string: device.webPolicy) ?? .blockAll,
      webPolicyDomains: domains.map(\.domain),
      customBlockRules: blockRules.map { .init(id: $0.id, rule: $0.rule) }
    )
  }
}
