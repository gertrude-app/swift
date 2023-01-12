import Shared
import SharedCore

final class AppLogger: GertieLogger {
  weak var store: AppStore?
  var appWindow: LoggerProtocol = NullLogger()
  var console: LoggerProtocol = NullLogger()
  var honeycomb: LoggerProtocol = NullLogger()
  var debugSession: DebugSession?

  #if DEBUG
    var xcode: LoggerProtocol = NullLogger()
  #endif

  var debugging: Bool {
    debugSession != nil
  }

  init(store: AppStore?) {
    self.store = store
    configureAll()
  }

  func endDebugSession() {
    guard let session = debugSession else { return }
    AppCore.log(.debugSession(.ended(session)))
    debugSession = nil
    configureHoneycomb()
  }

  func startDebugSession(_ session: DebugSession) {
    honeycomb.flush()
    debugSession = session
    AppCore.log(.debugSession(.started(session)))
    honeycomb = SelectiveLogger.make(
      config: .debug,
      wrapped: ExpiringLogger(
        expiration: session.expiration,
        wrapped: Honeycomb.AppLogger(
          debugSessionId: session.id,
          batchSize: isDev() ? 10 : 100,
          batchInterval: isDev() ? 15 : 60,
          getIsConnected: { Current.connection.isConnected() },
          send: { Current.honeycomb.send($0) }
        ),
        onExpiration: { [weak self] in
          AppCore.log(.debugSession(.ended(session)))
          self?.debugSession = nil
          self?.configureHoneycomb()
        }
      )
    )
  }

  func configureConsole() {
    console = SelectiveLogger.make(
      config: store?.state.logging.toConsole == true ? .debug : .none,
      wrapped: OsLogger()
    )
    #if DEBUG
      xcode = SelectiveLogger.make(
        config: console is NullLogger ? .debug : .none,
        wrapped: XcodeLogger()
      )
    #endif
  }

  func configureAppWindow() {
    appWindow = SelectiveLogger.make(
      config: store?.state.logging.toAppWindow == true ? .debug : .none,
      wrapped: AppWindowLogger(store: store)
    )
  }

  func configureHoneycomb() {
    guard !debugging else { return }
    honeycomb.flush()
    honeycomb = SelectiveLogger.make(
      config: .notice,
      wrapped: Honeycomb.AppLogger(
        getIsConnected: { Current.connection.isConnected() },
        send: { Current.honeycomb.send($0) }
      )
    )
  }

  public func log(_ message: Log.Message) {
    honeycomb.log(message)
    console.log(message)
    appWindow.log(message)
    #if DEBUG
      xcode.log(message)
    #endif
  }
}
