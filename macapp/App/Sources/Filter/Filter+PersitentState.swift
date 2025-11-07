import Core
import Foundation
import Gertie

public enum Persistent {
  public typealias State = V2

  // v2.5.0 - *
  public struct V2: PersistentState, Sendable {
    public static let version = 2
    public var userKeychains: [uid_t: [RuleKeychain]] = [:]
    public var userDowntime: [uid_t: PlainTimeWindow] = [:]
    public var appIdManifest = AppIdManifest()
    public var exemptUsers: Set<uid_t> = []
  }

  // v2.0.0 - v2.4.0
  public struct V1: PersistentState, Sendable {
    public static let version = 1
    public var userKeys: [uid_t: [RuleKey]] = [:]
    public var appIdManifest = AppIdManifest()
    public var exemptUsers: Set<uid_t> = []
  }
}

extension Filter.State {
  var persistent: Persistent.State {
    .init(
      userKeychains: self.userKeychains,
      userDowntime: self.userDowntime.mapValues { $0.window },
      appIdManifest: self.appIdManifest,
      exemptUsers: self.exemptUsers,
    )
  }
}
