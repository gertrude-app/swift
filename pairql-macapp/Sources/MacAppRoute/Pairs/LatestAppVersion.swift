import Foundation
import Gertie
import PairQL

extension ReleaseChannel: PairInput {}

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

  public struct Output: PairOutput {
    public struct Pace: PairOutput {
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
}
