import MacAppRoute

extension GetUserData: NoInputResolver {
  static func resolve(in context: UserContext) async throws -> Output {
    let userDevice = try await context.userDevice()
    return Output(
      id: context.user.id.rawValue,
      token: context.token.value.rawValue,
      deviceId: userDevice.id.rawValue,
      name: context.user.name,
      keyloggingEnabled: context.user.keyloggingEnabled,
      screenshotsEnabled: context.user.screenshotsEnabled,
      screenshotFrequency: context.user.screenshotsFrequency,
      screenshotSize: context.user.screenshotsResolution,
      connectedAt: userDevice.createdAt
    )
  }
}
