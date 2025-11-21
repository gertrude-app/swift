import DuetSQL
import IOSRoute

extension ConnectedRules: Resolver {
  static func resolve(with input: Input, in ctx: IOSApp.ChildContext) async throws -> Output {
    let groups = try await ctx.device.blockGroups(in: ctx.db)
    let blockRules = try await IOSApp.BlockRule.query()
      .where(.or(
        .groupId |=| groups.map { .uuid($0.id) },
        .deviceId == ctx.device.id,
      ))
      .orderBy(.id, .asc)
      .all(in: ctx.db)
      .map(\.rule)

    var device = ctx.device
    device.vendorId = .init(input.vendorId)
    device.deviceType = input.deviceType
    device.appVersion = input.appVersion
    device.iosVersion = input.iosVersion
    if device != ctx.device {
      try await ctx.db.update(device)
    }

    return try await .init(
      blockRules: blockRules,
      webPolicy: ctx.device.webContentFilterPolicy(in: ctx.db),
    )
  }
}
