import Gertie
import MacAppRoute

extension CheckIn: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    async let v1 = RefreshRules.resolve(with: .init(appVersion: input.appVersion), in: context)
    async let admin = context.user.admin()
    async let userDevice = context.userDevice()
    async let browsers = Browser.query().all()
    let adminDevice = try await userDevice.adminDevice()
    let channel = adminDevice.appReleaseChannel

    async let latestRelease = LatestAppVersion.resolve(
      with: .init(releaseChannel: channel, currentVersion: input.appVersion),
      in: .init(requestId: context.requestId, dashboardUrl: context.dashboardUrl)
    )

    if let filterVersionSemver = input.filterVersion,
       let filterVersion = Semver(filterVersionSemver),
       filterVersion != adminDevice.filterVersion {
      adminDevice.filterVersion = filterVersion
      try await adminDevice.save()
    }

    return Output(
      adminAccountStatus: try await admin.accountStatus,
      appManifest: try await v1.appManifest,
      keys: try await v1.keys,
      latestRelease: try await latestRelease,
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
      ),
      browsers: try await browsers.map(\.match)
    )
  }
}
