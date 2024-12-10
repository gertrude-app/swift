import Foundation
import Gertie
import PairQL

/// in use: v2.5.0 - present
public struct CheckIn_v2: Pair {
  public static let auth: ClientAuth = .user

  public struct Input: PairInput {
    public var appVersion: String
    public var filterVersion: String?
    public var userIsAdmin: Bool?
    public var osVersion: String?
    public var pendingFilterSuspension: UUID?
    public var pendingUnlockRequests: [UUID]?

    public init(
      appVersion: String,
      filterVersion: String?,
      userIsAdmin: Bool? = nil,
      osVersion: String? = nil,
      pendingFilterSuspension: UUID? = nil,
      pendingUnlockRequests: [UUID]? = nil
    ) {
      self.appVersion = appVersion
      self.filterVersion = filterVersion
      self.userIsAdmin = userIsAdmin
      self.osVersion = osVersion
      self.pendingFilterSuspension = pendingFilterSuspension
      self.pendingUnlockRequests = pendingUnlockRequests
    }
  }

  public struct LatestRelease: PairNestable {
    public struct Pace: PairNestable {
      public var nagOn: Date
      public var requireOn: Date

      public init(nagOn: Date, requireOn: Date) {
        self.nagOn = nagOn
        self.requireOn = requireOn
      }
    }

    public var semver: String
    public var pace: Pace?

    public init(semver: String, pace: Pace? = nil) {
      self.semver = semver
      self.pace = pace
    }
  }

  public struct ResolvedFilterSuspension: PairNestable {
    public var id: UUID
    public var decision: FilterSuspensionDecision
    public var comment: String?

    public init(id: UUID, decision: FilterSuspensionDecision, comment: String?) {
      self.id = id
      self.decision = decision
      self.comment = comment
    }
  }

  public struct ResolvedUnlockRequest: PairNestable {
    public var id: UUID
    public var status: RequestStatus
    public var target: String
    public var comment: String?

    public init(id: UUID, status: RequestStatus, target: String, comment: String?) {
      self.id = id
      self.status = status
      self.target = target
      self.comment = comment
    }
  }

  public struct Output: PairOutput {
    public var adminAccountStatus: AdminAccountStatus
    public var appManifest: AppIdManifest
    public var keychains: [RuleKeychain]
    public var latestRelease: LatestRelease
    public var updateReleaseChannel: ReleaseChannel
    public var userData: UserData
    public var browsers: [BrowserMatch]
    public var resolvedFilterSuspension: ResolvedFilterSuspension?
    public var resolvedUnlockRequests: [ResolvedUnlockRequest]?
    public var trustedTime: Double
    /// introduced in v2.6.0, but backwards compatible
    public var blockedApps: [BlockedApp]

    public init(
      adminAccountStatus: AdminAccountStatus,
      appManifest: AppIdManifest,
      keychains: [RuleKeychain],
      latestRelease: LatestRelease,
      updateReleaseChannel: ReleaseChannel,
      userData: UserData,
      browsers: [BrowserMatch],
      resolvedFilterSuspension: ResolvedFilterSuspension? = nil,
      resolvedUnlockRequests: [ResolvedUnlockRequest]? = nil,
      blockedApps: [BlockedApp] = [],
      trustedTime: Double
    ) {
      self.adminAccountStatus = adminAccountStatus
      self.appManifest = appManifest
      self.keychains = keychains
      self.latestRelease = latestRelease
      self.updateReleaseChannel = updateReleaseChannel
      self.userData = userData
      self.browsers = browsers
      self.resolvedFilterSuspension = resolvedFilterSuspension
      self.resolvedUnlockRequests = resolvedUnlockRequests
      self.blockedApps = blockedApps
      self.trustedTime = trustedTime
    }
  }
}

#if DEBUG
  extension CheckIn_v2.Output: Mocked {
    public static let mock = Self(
      adminAccountStatus: .active,
      appManifest: .mock,
      keychains: [.init(id: UUID(), keys: [.init(id: UUID(), key: .mock)])],
      latestRelease: .init(semver: "2.0.4"),
      updateReleaseChannel: .stable,
      userData: .mock {
        $0.keyloggingEnabled = true
        $0.screenshotsEnabled = true
        $0.screenshotFrequency = 333
        $0.screenshotSize = 555
      },
      browsers: [.name("Safari"), .bundleId("com.apple.Safari")],
      blockedApps: [],
      trustedTime: 0.0
    )

    public static let empty = Self(
      adminAccountStatus: .active,
      appManifest: .empty,
      keychains: [],
      latestRelease: .init(semver: "2.0.4"),
      updateReleaseChannel: .stable,
      userData: .empty,
      browsers: [],
      blockedApps: [],
      trustedTime: 0.0
    )
  }
#endif
