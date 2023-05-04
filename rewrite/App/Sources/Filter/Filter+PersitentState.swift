import Core
import Foundation
import Shared

public enum Persistent {
  public typealias State = V1

  public struct V1: PersistentState, Sendable {
    public static let version = 1
    public var userKeys: [uid_t: [FilterKey]] = [:]
    public var appIdManifest = AppIdManifest()
    public var exemptUsers: Set<uid_t> = []
  }
}

extension Filter.State {
  var persistent: Persistent.State {
    .init(
      userKeys: userKeys,
      appIdManifest: appIdManifest,
      exemptUsers: exemptUsers
    )
  }
}
