import Foundation
import Gertie
import PairQL

/// deprecated: v2.0.0 - v2.0.3
/// remove when v2.0.4 is MSV
public struct RefreshRules: Pair {
  public static var auth: ClientAuth = .user

  public typealias Input = CheckIn.Input

  public struct Output: PairOutput {
    public var appManifest: AppIdManifest
    public var keyloggingEnabled: Bool
    public var screenshotsEnabled: Bool
    public var screenshotsFrequency: Int
    public var screenshotsResolution: Int
    public var keys: [CheckIn.Key]

    public init(
      appManifest: AppIdManifest,
      keyloggingEnabled: Bool,
      screenshotsEnabled: Bool,
      screenshotsFrequency: Int,
      screenshotsResolution: Int,
      keys: [CheckIn.Key]
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

#if DEBUG
  extension RefreshRules.Output: Mocked {
    public static let mock = Self(
      appManifest: .mock,
      keyloggingEnabled: true,
      screenshotsEnabled: true,
      screenshotsFrequency: 333,
      screenshotsResolution: 555,
      keys: [.init(id: UUID(), key: .mock)]
    )

    public static let empty = Self(
      appManifest: .empty,
      keyloggingEnabled: false,
      screenshotsEnabled: false,
      screenshotsFrequency: 0,
      screenshotsResolution: 0,
      keys: []
    )
  }
#endif
