import DuetSQL
import Foundation
import GertieIOS
import PairQL
import Vapor

struct UpdateIOSDevice: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var deviceId: IOSApp.Device.Id
    var enabledBlockGroups: [IOSApp.BlockGroup.Id]
    var webPolicy: WebContentFilterPolicy.Kind
    var webPolicyDomains: [String]
  }
}

extension UpdateIOSDevice: Resolver {
  static func resolve(with input: Input, in ctx: ParentContext) async throws -> Output {
    var device = try await ctx.db.find(input.deviceId)
    let children = try await ctx.children()
    guard children.first(where: { $0.id == device.childId }) != nil else {
      throw Abort(.unauthorized)
    }
    let deletedPivots = try await IOSApp.DeviceBlockGroup.query()
      .where(.deviceId == input.deviceId)
      .all(in: ctx.db)
    try await IOSApp.DeviceBlockGroup.query()
      .where(.id |=| deletedPivots.map(\.id))
      .delete(in: ctx.db)
    do {
      try await ctx.db.create(input.enabledBlockGroups.map { blockGroupId in
        IOSApp.DeviceBlockGroup(
          deviceId: input.deviceId,
          blockGroupId: blockGroupId,
        )
      })
    } catch {
      try await ctx.db.create(deletedPivots)
    }

    device.webPolicy = input.webPolicy.rawValue
    try await ctx.db.update(device)

    try await IOSApp.WebPolicyDomain.query()
      .where(.deviceId == input.deviceId)
      .delete(in: ctx.db)

    try await ctx.db.create(input.webPolicyDomains.map {
      IOSApp.WebPolicyDomain(deviceId: input.deviceId, domain: $0)
    })

    return .success
  }
}
