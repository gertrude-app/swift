import Foundation
import XCore

public struct NullLogger: LoggerProtocol {
  public init() {}
  public func log(_ message: Log.Message) {}
}

public struct CombinedLogger: LoggerProtocol {
  public var loggers: [LoggerProtocol] = []

  public static func make(loggers: [LoggerProtocol] = []) -> LoggerProtocol {
    let filtered = loggers.filter { $0 is NullLogger == false }
    if filtered.isEmpty {
      return NullLogger()
    } else {
      return CombinedLogger(loggers: filtered)
    }
  }

  public func log(_ message: Log.Message) {
    for logger in loggers {
      logger.log(message)
    }
  }

  public func flush() {
    for logger in loggers {
      logger.flush()
    }
  }
}

#if os(macOS)
  import os.log
#endif

public struct OsLogger: LoggerProtocol {
  public init() {}

  public func log(_ logMsg: Log.Message) {
    #if os(macOS)
      let encoder = JSONEncoder()
      encoder.outputFormatting = .prettyPrinted
      let data = try? encoder.encode(logMsg.meta)
      let json = data.flatMap { String(data: $0, encoding: .utf8) }
      os_log(
        "%{public}s %{public}s %{public} s%{public}s",
        logMsg.level.emoji,
        "[G•\(logMsg.level.rawValue.uppercased())]",
        logMsg.message,
        "\n\n== meta ==\n\n\(json ?? "")"
      )
    #endif
  }
}

public struct FnLogger: LoggerProtocol {
  private var send: (Log.Message) -> Void

  public init(send: @escaping (Log.Message) -> Void) {
    self.send = send
  }

  public func log(_ message: Log.Message) {
    send(message)
  }
}

public class ExpiringLogger: LoggerProtocol {
  var expiration: Date?
  var wrapped: LoggerProtocol
  var onExpiration: () -> Void

  public init(
    expiration: Date,
    wrapped: LoggerProtocol,
    onExpiration: (() -> Void)? = nil
  ) {
    self.expiration = expiration
    self.wrapped = wrapped
    self.onExpiration = onExpiration ?? {}
  }

  public func log(_ message: Log.Message) {
    guard let expiration = expiration else {
      return
    }

    wrapped.log(message)

    if Date() >= expiration {
      self.expiration = nil
      wrapped = NullLogger()
      onExpiration()
    }
  }
}

public struct SelectiveLogger: LoggerProtocol {
  var config: Log.Config
  var wrapped: LoggerProtocol

  public static func make(config: Log.Config, wrapped: LoggerProtocol) -> LoggerProtocol {
    if config == .all {
      return wrapped
    } else if config == .none {
      return NullLogger()
    } else {
      return self.init(config: config, wrapped: wrapped)
    }
  }

  public func log(_ logMsg: Log.Message) {
    let rate = config.rate(for: logMsg.level)

    guard rate.test() else {
      return
    }

    return wrapped.log(.init(
      date: logMsg.date,
      level: logMsg.level,
      message: logMsg.message,
      meta: logMsg.meta,
      sampleRate: rate
    ))
  }
}
