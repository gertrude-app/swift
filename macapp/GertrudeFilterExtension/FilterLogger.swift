import FilterCore
import Shared
import SharedCore

final class FilterLogger: GertieLogger {
  var appWindow: LoggerProtocol = NullLogger()
  var console: LoggerProtocol = NullLogger()
  var honeycomb: LoggerProtocol = NullLogger()
  var debugSession: DebugSession?

  init() {
    configureAll()
  }

  var debugging: Bool {
    debugSession != nil
  }

  func startDebugSession(_ session: DebugSession) {
    honeycomb.flush()
    debugSession = session
    honeycomb = SelectiveLogger.make(
      config: .debug,
      wrapped: ExpiringLogger(
        expiration: session.expiration,
        wrapped: Honeycomb.FilterLogger(
          debugSessionId: session.id,
          send: SendToApp.batchedHoneycombLogs(_:),
          batchSize: isDev() ? 10 : 100,
          batchInterval: isDev() ? 15 : 60,
          scheduler: .main
        ),
        onExpiration: { [weak self] in
          self?.debugSession = nil
          self?.configureHoneycomb()
        }
      )
    )
  }

  func endDebugSession() {
    debugSession = nil
    configureHoneycomb()
  }

  func configureConsole() {
    console = SelectiveLogger.make(
      config: FilterStorage.loadLoggingConfig(for: .console) ?? .none,
      wrapped: OsLogger()
    )
  }

  func configureHoneycomb() {
    guard !debugging else { return }
    honeycomb.flush()
    honeycomb = SelectiveLogger.make(
      config: FilterStorage.loadLoggingConfig(for: .honeycomb) ?? .filterHoneycombDefault,
      wrapped: Honeycomb.FilterLogger(
        send: SendToApp.batchedHoneycombLogs(_:),
        scheduler: .main
      )
    )
  }

  public func log(_ message: Log.Message) {
    honeycomb.log(message)
    console.log(message)
    appWindow.log(message)
  }
}
