import Foundation
import Gertie
import PairQL

/// deprecated: v2.0.4 - v2.4.0
/// remove when MSV is 2.5.0
public struct CheckIn: Pair {
  public static let auth: ClientAuth = .user
  public typealias Input = CheckIn_v2.Input

  public struct Output: PairOutput {
    public var adminAccountStatus: AdminAccountStatus
    public var appManifest: AppIdManifest
    public var keys: [CheckIn_v2.RuleKey]
    public var latestRelease: CheckIn_v2.LatestRelease
    public var updateReleaseChannel: ReleaseChannel
    public var userData: UserData
    public var browsers: [BrowserMatch]
    public var resolvedFilterSuspension: CheckIn_v2.ResolvedFilterSuspension?
    public var resolvedUnlockRequests: [CheckIn_v2.ResolvedUnlockRequest]?

    public init(
      adminAccountStatus: AdminAccountStatus,
      appManifest: AppIdManifest,
      keys: [CheckIn_v2.RuleKey],
      latestRelease: CheckIn_v2.LatestRelease,
      updateReleaseChannel: ReleaseChannel,
      userData: UserData,
      browsers: [BrowserMatch],
      resolvedFilterSuspension: CheckIn_v2.ResolvedFilterSuspension? = nil,
      resolvedUnlockRequests: [CheckIn_v2.ResolvedUnlockRequest]? = nil
    ) {
      self.adminAccountStatus = adminAccountStatus
      self.appManifest = appManifest
      self.keys = keys
      self.latestRelease = latestRelease
      self.updateReleaseChannel = updateReleaseChannel
      self.userData = userData
      self.browsers = browsers
      self.resolvedFilterSuspension = resolvedFilterSuspension
      self.resolvedUnlockRequests = resolvedUnlockRequests
    }
  }
}

#if DEBUG
  extension CheckIn.Output: Mocked {
    public static let mock = Self(
      adminAccountStatus: .active,
      appManifest: .mock,
      keys: [.init(id: UUID(), key: .mock)],
      latestRelease: .init(semver: "2.0.4"),
      updateReleaseChannel: .stable,
      userData: .mock {
        $0.keyloggingEnabled = true
        $0.screenshotsEnabled = true
        $0.screenshotFrequency = 333
        $0.screenshotSize = 555
      },
      browsers: [.name("Safari"), .bundleId("com.apple.Safari")]
    )

    public static let empty = Self(
      adminAccountStatus: .active,
      appManifest: .empty,
      keys: [],
      latestRelease: .init(semver: "2.0.4"),
      updateReleaseChannel: .stable,
      userData: .empty,
      browsers: []
    )
  }
#endif
