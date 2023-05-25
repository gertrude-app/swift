import Foundation
import Gertie

public struct DebugSession: Equatable, Codable {
  public var id: UUID
  public var expiration: Date

  public var isExpired: Bool {
    Date() > expiration
  }

  public init(id: UUID, expiration: Date) {
    self.id = id
    self.expiration = expiration
  }
}

public enum AppToFilterLoggingCommand: Codable {
  case startAppWindowLogging
  case stopAppWindowLogging
  case startDebugSession(DebugSession)
  case endDebugSession
  case setPersistentConsoleConfig(Log.Config)
  case setPersistentHoneycombConfig(Log.Config)
}

public struct LoggingState: Equatable {
  public var console: Log.Config
  public var appWindow: Log.Config
  public var honeycomb: Log.Config

  public init(
    console: Log.Config,
    appWindow: Log.Config,
    honeycomb: Log.Config
  ) {
    self.console = console
    self.appWindow = appWindow
    self.honeycomb = honeycomb
  }
}

// extensions

public extension Log.Config {
  static let filterHoneycombDefault = Self(
    trace: .none,
    debug: .none,
    info: .none,
    notice: .all,
    warn: .all,
    error: .all
  )
}

extension LoggingState: Codable, IPCTransmitable {}
