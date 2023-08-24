import Core
import Gertie

enum Persistent {
  typealias State = V2

  // v2.0.4 - *
  struct V2: PersistentState {
    static let version = 2
    var appVersion: String
    var appUpdateReleaseChannel: ReleaseChannel
    var filterVersion: String
    var user: UserData?
  }

  // v2.0.0 - v2.0.3
  struct V1: PersistentState {
    static let version = 1
    var appVersion: String
    var appUpdateReleaseChannel: ReleaseChannel
    var user: UserData?
  }
}

extension AppReducer.State {
  var persistent: Persistent.State {
    .init(
      appVersion: appUpdates.installedVersion,
      appUpdateReleaseChannel: appUpdates.releaseChannel,
      filterVersion: filter.version,
      user: user.data
    )
  }
}
