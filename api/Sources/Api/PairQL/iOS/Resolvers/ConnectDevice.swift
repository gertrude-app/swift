import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute

extension ConnectDevice: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    guard let childId = await with(dependency: \.ephemeral)
      .getPendingAppConnection(input.verificationCode) else {
      throw context.error(
        id: "79483727",
        type: .unauthorized,
        debugMessage: "verification code not found",
        userMessage: "Connection code expired, or not found. Plese create a new code and try again.",
        appTag: .connectionCodeNotFound
      )
    }

    let child = try await context.db.find(childId)
    let device = try await context.db.create(IOSApp.Device(
      childId: childId,
      vendorId: .init(input.vendorId),
      deviceType: input.deviceType,
      appVersion: input.appVersion,
      iosVersion: input.iosVersion
    ))
    let token = try await context.db.create(IOSApp.Token(deviceId: device.id))

    return .init(
      childId: child.id.rawValue,
      token: token.value.rawValue,
      deviceId: device.id.rawValue,
      childName: child.name
    )
  }
}
