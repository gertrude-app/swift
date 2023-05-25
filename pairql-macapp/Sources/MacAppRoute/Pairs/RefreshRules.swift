import Foundation
import Gertie
import PairQL

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
    public let key: Gertie.Key

    public init(id: UUID, key: Gertie.Key) {
      self.id = id
      self.key = key
    }
  }

  public struct Output: PairOutput {
    public var appManifest: AppIdManifest
    public var keyloggingEnabled: Bool
    public var screenshotsEnabled: Bool
    public var screenshotsFrequency: Int
    public var screenshotsResolution: Int
    public var keys: [Key]

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

#if DEBUG
  public extension RefreshRules.Output {
    static let mock = Self(
      appManifest: .init(),
      keyloggingEnabled: true,
      screenshotsEnabled: true,
      screenshotsFrequency: 333,
      screenshotsResolution: 555,
      keys: []
    )

    static func mock(configure: (inout Self) -> Void) -> Self {
      var mock = Self.mock
      configure(&mock)
      return mock
    }
  }
#endif
