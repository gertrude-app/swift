import Models

extension FilterState {
  var menuBar: MenuBarFeature.State.Connected.FilterState {
    switch self {
    // TODO... handle error separately?
    case .unknown, .notInstalled, .off, .errorLoadingConfig:
      return .off
    case .on:
      return .on
    case .suspended(let resuming):
      return .suspended(expiration: "\(resuming)") // TODO:
    }
  }
}

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
          filterState: filter.menuBar,
          recordingScreen: user.screenshotsEnabled,
          recordingKeystrokes: user.keyloggingEnabled
        ))
      case .notConnected:
        return .notConnected
      }
    }
    set {}
  }
}