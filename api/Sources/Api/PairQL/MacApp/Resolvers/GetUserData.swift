import DuetSQL
import MacAppRoute

extension GetUserData: NoInputResolver {
  static func resolve(in context: UserContext) async throws -> Output {
    let device = try await context.device()
    return Output(
      id: context.user.id.rawValue,
      token: context.token.value.rawValue,
      deviceId: device.id.rawValue,
      name: context.user.name,
      keyloggingEnabled: context.user.keyloggingEnabled,
      screenshotsEnabled: context.user.screenshotsEnabled,
      screenshotFrequency: context.user.screenshotsFrequency,
      screenshotSize: context.user.screenshotsResolution,
      connectedAt: device.createdAt
    )
  }
}
