import Foundation
import Gertie
import PairQL

/// deprecated: v2.0.0 - v2.0.3
/// remove when v2.0.4 is MSV
public struct LatestAppVersion: Pair {
  public static var auth: ClientAuth = .user

  public struct Input: PairInput {
    public var releaseChannel: ReleaseChannel
    public var currentVersion: String

    public init(releaseChannel: ReleaseChannel, currentVersion: String) {
      self.releaseChannel = releaseChannel
      self.currentVersion = currentVersion
    }
  }

  public typealias Output = CheckIn.LatestRelease
}

extension CheckIn.LatestRelease: PairOutput {}

extension ReleaseChannel: PairInput {}
