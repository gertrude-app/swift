import Core
import Models

enum Persistent {
  typealias State = V1

  struct V1: PersistentState {
    static let version = 1
    var appVersion: String
    var user: User?
  }
}

extension AppReducer.State {
  var persistent: Persistent.State {
    .init(appVersion: appUpdates.installedVersion, user: user)
  }
}
