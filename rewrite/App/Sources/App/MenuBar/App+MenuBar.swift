import Dependencies
import Models

extension AppReducer.State {
  var menuBar: MenuBarFeature.State {
    get {
      switch history.userConnection {
      case .connectFailed(let error):
        return .connectionFailed(error: error)
      case .connecting:
        return .connecting
      case .enteringConnectionCode:
        return .enteringConnectionCode
      case .established(let welcomeDismissed):
        guard let user else {
          return .connectionFailed(error: "Unexpected error, please reconnect") // TODO:
        }
        guard welcomeDismissed else {
          return .connectionSucceded(userName: user.name)
        }
        return .connected(.init(
          filterState: .init(self),
          recordingScreen: user.screenshotsEnabled,
          recordingKeystrokes: user.keyloggingEnabled,
          adminAttentionRequired: somethingRequiresAdminAttention
        ))
      case .notConnected:
        return .notConnected
      }
    }
    set {}
  }

  var somethingRequiresAdminAttention: Bool {
    if admin.accountStatus != .active {
      return true
    }

    let health = adminWindow.healthCheck
    if case .ok(value: let latest) = health.latestAppVersion,
       latest != appUpdates.installedVersion {
      return false
    }

    switch health.filterStatus {
    case .some(.communicationBroken),
         .some(.unexpected):
      return true
    case .some(.installed(let version, let numUserKeys)):
      if version != appUpdates.installedVersion || numUserKeys == 0 {
        return true
      }
    default:
      break
    }

    if case .ok(value: .admin) = health.macOsUserType {
      return true
    }

    switch health.notificationsSetting {
    case .some(.none), .some(.banner):
      return true
    default:
      break
    }

    if health.screenRecordingPermissionOk == false {
      return true
    }

    if health.keystrokeRecordingPermissionOk == false {
      return true
    }

    return false
  }
}
