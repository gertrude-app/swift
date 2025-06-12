import DuetSQL
import IOSRoute

/// testflight only: v1.4.0 - present
extension BlockRules_v3: Resolver {
  static func resolve(with input: Input, in ctx: IOSApp.ChildContext) async throws -> Output {
    let groups = try await ctx.device.blockGroups(in: ctx.db)
    let blockRules = try await IOSApp.BlockRule.query()
      .where(.or(
        .groupId |=| groups.map { .uuid($0.id) },
        .deviceId == ctx.device.id
      ))
      .orderBy(.id, .asc)
      .all(in: ctx.db)
      .map(\.rule)

    let policyModel = try? await IOSApp.WebPolicy.query()
      .where(.deviceId == ctx.device.id)
      .first(in: ctx.db)

    if policyModel == nil {
      await with(dependency: \.slack)
        .error("unexpected missing ios device web policy `\(ctx.device.id)`")
    }

    var device = ctx.device
    device.vendorId = .init(input.vendorId)
    device.deviceType = input.deviceType
    device.appVersion = input.appVersion
    device.iosVersion = input.iosVersion
    if device != ctx.device {
      try await ctx.db.update(device)
    }

    return .init(
      blockRules: blockRules,
      webPolicy: policyModel?.policy ?? .blockAll
    )
  }
}
