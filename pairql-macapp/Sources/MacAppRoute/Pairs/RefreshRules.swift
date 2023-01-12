import Foundation
import PairQL
import Shared

public struct RefreshRules: Pair {
  public static var auth: ClientAuth = .user

  public struct Input: PairInput {
    public var appVersion: String

    public init(appVersion: String) {
      self.appVersion = appVersion
    }
  }

  public struct Key: PairNestable {
    public let id: UUID
    public let key: Shared.Key

    public init(id: UUID, key: Shared.Key) {
      self.id = id
      self.key = key
    }
  }

  public struct Output: PairOutput {
    public let appManifest: AppIdManifest
    public let keyloggingEnabled: Bool
    public let screenshotsEnabled: Bool
    public let screenshotsFrequency: Int
    public let screenshotsResolution: Int
    public let keys: [Key]

    public init(
      appManifest: AppIdManifest,
      keyloggingEnabled: Bool,
      screenshotsEnabled: Bool,
      screenshotsFrequency: Int,
      screenshotsResolution: Int,
      keys: [Key]
    ) {
      self.appManifest = appManifest
      self.keyloggingEnabled = keyloggingEnabled
      self.screenshotsEnabled = screenshotsEnabled
      self.screenshotsFrequency = screenshotsFrequency
      self.screenshotsResolution = screenshotsResolution
      self.keys = keys
    }
  }
}
