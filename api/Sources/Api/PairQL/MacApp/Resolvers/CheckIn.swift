import Gertie
import MacAppRoute

extension CheckIn: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    async let v1 = RefreshRules.resolve(with: input, in: context)
    async let admin = context.user.admin()
    async let userDevice = context.userDevice()
    let channel = try await userDevice.adminDevice().appReleaseChannel
    async let latestRelease = LatestAppVersion.resolve(
      with: .init(releaseChannel: channel, currentVersion: input.appVersion),
      in: .init(requestId: context.requestId, dashboardUrl: context.dashboardUrl)
    )

    return Output(
      adminAccountStatus: try await admin.accountStatus,
      appManifest: try await v1.appManifest,
      keys: try await v1.keys,
      latestRelease: Semver(try await latestRelease.semver)!,
      updateReleaseChannel: channel,
      userData: .init(
        id: context.user.id.rawValue,
        token: context.token.value.rawValue,
        deviceId: try await userDevice.id.rawValue,
        name: context.user.name,
        keyloggingEnabled: context.user.keyloggingEnabled,
        screenshotsEnabled: context.user.screenshotsEnabled,
        screenshotFrequency: context.user.screenshotsFrequency,
        screenshotSize: context.user.screenshotsResolution,
        connectedAt: try await userDevice.createdAt
      )
    )
  }
}
