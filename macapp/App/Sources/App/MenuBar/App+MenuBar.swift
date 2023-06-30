import ClientInterfaces
import Dependencies
import Gertie

extension MenuBarFeature.State {
  enum View: Equatable, Encodable {
    struct Connected: Equatable, Encodable {
      enum UpdateStatus: String, Equatable, Codable {
        case available
        case nag
        case require
      }

      var filterState: FilterState
      var recordingScreen: Bool
      var recordingKeystrokes: Bool
      var adminAttentionRequired: Bool
      var updateStatus: UpdateStatus?
    }

    case notConnected
    case enteringConnectionCode
    case connecting
    case connectionFailed(error: String)
    case connectionSucceded(userName: String)
    case connected(Connected)
  }
}

extension AppReducer.State {
  var menuBarView: MenuBarFeature.State.View {
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
          unexpectedError(id: "ad104cdc")
          return .connectionFailed(error: "Unexpected error, please reconnect")
        }
        guard welcomeDismissed else {
          return .connectionSucceded(userName: user.name)
        }
        return .connected(.init(
          filterState: .init(self),
          recordingScreen: user.screenshotsEnabled,
          recordingKeystrokes: user.keyloggingEnabled,
          adminAttentionRequired: somethingRequiresAdminAttention,
          updateStatus: updateStatus
        ))
      case .notConnected:
        return .notConnected
      }
    }
    set {}
  }

  var updateStatus: MenuBarFeature.State.View.Connected.UpdateStatus? {
    guard let latest = appUpdates.latestVersion else {
      return nil
    }
    guard let latestSemver = Semver(latest.semver),
          let current = Semver(appUpdates.installedVersion) else {
      unexpectedError(id: "76c483a9")
      return nil
    }
    guard latestSemver > current else {
      return nil
    }
    guard let pace = latest.pace else {
      return .available
    }

    // TODO: don't show nag if not connected to the internet

    @Dependency(\.date.now) var now
    if now <= pace.nagOn {
      return .available
    }
    if now > pace.nagOn, now < pace.requireOn {
      return now < (appUpdates.updateNagDismissedUntil ?? .distantPast) ? .available : .nag
    }
    if now >= pace.requireOn {
      return .require
    }
    return nil
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
