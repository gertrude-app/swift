import DuetSQL
import Gertie
import MacAppRoute

extension CheckIn: Resolver {
  static func resolve(with input: Input, in context: MacApp.ChildContext) async throws -> Output {
    let v2 = try await CheckIn_v2.resolve(with: input, in: context)
    return Output(
      adminAccountStatus: v2.adminAccountStatus,
      appManifest: v2.appManifest,
      keys: v2.keychains.flatMap(\.keys),
      latestRelease: v2.latestRelease,
      updateReleaseChannel: v2.updateReleaseChannel,
      userData: v2.userData,
      browsers: v2.browsers,
      resolvedFilterSuspension: v2.resolvedFilterSuspension,
      resolvedUnlockRequests: v2.resolvedUnlockRequests,
    )
  }
}
