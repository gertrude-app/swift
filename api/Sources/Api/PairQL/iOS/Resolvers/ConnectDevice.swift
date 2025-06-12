import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute

extension ConnectDevice: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    guard let childId = await with(dependency: \.ephemeral)
      .getPendingAppConnection(input.verificationCode) else {
      throw ctx.error(
        id: "79483727",
        type: .unauthorized,
        debugMessage: "verification code not found",
        userMessage: "Connection code expired, or not found. Please create a new code and try again.",
        appTag: .connectionCodeNotFound
      )
    }

    let child = try await ctx.db.find(childId)
    let device = try await ctx.db.create(IOSApp.Device(
      childId: childId,
      vendorId: .init(input.vendorId),
      deviceType: input.deviceType,
      appVersion: input.appVersion,
      iosVersion: input.iosVersion
    ))
    let token = try await ctx.db.create(IOSApp.Token(deviceId: device.id))
    try await ctx.db.create(IOSApp.WebPolicy(deviceId: device.id, policy: .blockAdult))

    // start with ALL block groups, parent controls from web ui
    let groups = try await IOSApp.BlockGroup.query().all(in: ctx.db)
    try await ctx.db.create(groups.map {
      IOSApp.DeviceBlockGroup(deviceId: device.id, blockGroupId: $0.id)
    })

    return .init(
      childId: child.id.rawValue,
      token: token.value.rawValue,
      deviceId: device.id.rawValue,
      childName: child.name
    )
  }
}
