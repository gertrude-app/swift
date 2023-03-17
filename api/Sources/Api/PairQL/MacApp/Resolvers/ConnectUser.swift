import DuetSQL
import MacAppRoute
import Vapor

extension ConnectUser: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let v1 = try await ConnectApp.resolve(with: .init(
      verificationCode: input.verificationCode,
      appVersion: input.appVersion,
      hostname: input.hostname,
      modelIdentifier: input.modelIdentifier,
      username: input.username,
      fullUsername: input.fullUsername,
      numericId: input.numericId,
      serialNumber: input.serialNumber
    ), in: context)

    let user = try await Current.db.find(User.Id(v1.userId))

    return Output(
      id: user.id.rawValue,
      token: v1.token,
      deviceId: v1.deviceId,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotFrequency: user.screenshotsFrequency,
      screenshotSize: user.screenshotsResolution
    )
  }
}
