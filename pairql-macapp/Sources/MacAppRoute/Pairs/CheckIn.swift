import Foundation
import Gertie
import PairQL

/// in use: v2.0.4 - present
public struct CheckIn: Pair {
  public static var auth: ClientAuth = .user

  public struct Input: PairInput {
    public var appVersion: String

    public init(appVersion: String) {
      self.appVersion = appVersion
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

  public struct Output: PairOutput {
    public let adminAccountStatus: AdminAccountStatus
    public var appManifest: AppIdManifest
    public var keys: [Key]
    public var latestRelease: Semver
    public var updateReleaseChannel: ReleaseChannel
    public var userData: UserData

    public init(
      adminAccountStatus: AdminAccountStatus,
      appManifest: AppIdManifest,
      keys: [Key],
      latestRelease: Semver,
      updateReleaseChannel: ReleaseChannel,
      userData: UserData
    ) {
      self.adminAccountStatus = adminAccountStatus
      self.appManifest = appManifest
      self.keys = keys
      self.latestRelease = latestRelease
      self.updateReleaseChannel = updateReleaseChannel
      self.userData = userData
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
      latestRelease: "2.0.4",
      updateReleaseChannel: .stable,
      userData: .mock
    )

    public static let empty = Self(
      adminAccountStatus: .active,
      appManifest: .empty,
      keys: [],
      latestRelease: "2.0.4",
      updateReleaseChannel: .stable,
      userData: .empty
    )
  }
#endif
