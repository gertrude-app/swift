public extension GenericEventHandler {
  static func debug(_ msg: String) -> Self {
    .genericEvent(.debug(msg))
  }

  static func info(_ msg: String) -> Self {
    .genericEvent(.info(msg))
  }

  static func notice(_ msg: String) -> Self {
    .genericEvent(.notice(msg))
  }

  static func warn(_ msg: String) -> Self {
    .genericEvent(.warn(msg))
  }

  static func error(_ msg: String, _ error: Error?) -> Self {
    .genericEvent(.error(msg, error))
  }

  static func level(_ level: Log.Level, _ msg: String, _ meta: Log.Meta?) -> Self {
    .genericEvent(.level(level, msg, meta))
  }
}

public enum GenericEvent: LogMessagable {
  case level(Log.Level, String, Log.Meta?)
  case info(String)
  case notice(String)
  case warn(String)
  case debug(String)
  case error(String, Error?)

  public var logMessage: Log.Message {
    switch self {
    case .info(let text):
      return .info(text)
    case .notice(let text):
      return .notice(text)
    case .warn(let text):
      return .warn(text)
    case .debug(let text):
      return .debug(text)
    case .error(let text, let error):
      return .error(text, .error(error))
    case .level(let level, let text, let meta):
      return .init(level: level, message: text, meta: meta)
    }
  }
}
