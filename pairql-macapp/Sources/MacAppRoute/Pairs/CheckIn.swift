import Foundation
import Gertie
import PairQL

/// in use: v2.0.4 - present
public struct CheckIn: Pair {
  public static var auth: ClientAuth = .user

  public struct Input: PairInput {
    public var appVersion: String
    public var filterVersion: String?

    public init(appVersion: String, filterVersion: String?) {
      self.appVersion = appVersion
      self.filterVersion = filterVersion
    }
  }

  public struct Key: PairNestable {
    public let id: UUID
    public let key: Gertie.Key

    public init(id: UUID, key: Gertie.Key) {
      self.id = id
      self.key = key
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

  public struct Output: PairOutput {
    public var adminAccountStatus: AdminAccountStatus
    public var appManifest: AppIdManifest
    public var keys: [Key]
    public var latestRelease: LatestRelease
    public var updateReleaseChannel: ReleaseChannel
    public var userData: UserData
    public var browsers: [BrowserMatch]

    public init(
      adminAccountStatus: AdminAccountStatus,
      appManifest: AppIdManifest,
      keys: [Key],
      latestRelease: LatestRelease,
      updateReleaseChannel: ReleaseChannel,
      userData: UserData,
      browsers: [BrowserMatch]
    ) {
      self.adminAccountStatus = adminAccountStatus
      self.appManifest = appManifest
      self.keys = keys
      self.latestRelease = latestRelease
      self.updateReleaseChannel = updateReleaseChannel
      self.userData = userData
      self.browsers = browsers
    }
  }
}

#if DEBUG
  import Gertie

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
