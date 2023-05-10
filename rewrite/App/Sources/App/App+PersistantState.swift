import Core
import Models
import Shared

enum Persistent {
  typealias State = V1

  struct V1: PersistentState {
    static let version = 1
    var appVersion: String
    var appUpdateReleaseChannel: ReleaseChannel
    var user: User?
  }
}

extension AppReducer.State {
  var persistent: Persistent.State {
    .init(
      appVersion: appUpdates.installedVersion,
      appUpdateReleaseChannel: appUpdates.releaseChannel,
      user: user
    )
  }
}
