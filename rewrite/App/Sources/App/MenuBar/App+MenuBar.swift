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
          recordingKeystrokes: user.keyloggingEnabled
        ))
      case .notConnected:
        return .notConnected
      }
    }
    set {}
  }
}
