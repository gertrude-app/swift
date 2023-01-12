import Shared

public protocol GertieLogger: LoggerProtocol {
  var honeycomb: LoggerProtocol { get set }
  var console: LoggerProtocol { get set }
  var appWindow: LoggerProtocol { get set }

  func startDebugSession(_ session: DebugSession)
  func endDebugSession()
  func configureConsole()
  func configureAppWindow()
  func configureHoneycomb()
  func configureAll()
}

public struct GertieNullLogger: GertieLogger {
  public var honeycomb: LoggerProtocol = NullLogger()
  public var console: LoggerProtocol = NullLogger()
  public var appWindow: LoggerProtocol = NullLogger()
  public func startDebugSession(_ session: DebugSession) {}
  public func endDebugSession() {}
  public func log(_ message: Log.Message) {}

  public init() {}
}

public extension GertieLogger {
  func configureAll() {
    configureHoneycomb()
    configureConsole()
    configureAppWindow()
  }

  func configureHoneycomb() { /* noop */ }
  func configureAppWindow() { /* noop */ }
  func configureConsole() { /* noop */ }

  func flush() {
    honeycomb.flush()
    appWindow.flush()
    console.flush()
  }
}
