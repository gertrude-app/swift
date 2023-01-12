public protocol LoggerProtocol {
  func log(_ level: Log.Level, _ message: String, meta: Log.Meta?, sampleRate: Log.SampleRate?)
  func log(_ message: Log.Message)
  func flush()
}

public protocol LogMessagable {
  var logMessage: Log.Message { get }
}

public protocol GenericEventHandler {
  static func genericEvent(_ event: GenericEvent) -> Self
}

// extensions

public extension LoggerProtocol {
  func flush() { /* noop */ }
  
  func log(_ level: Log.Level, _ message: String, meta: Log.Meta?, sampleRate: Log.SampleRate?) {
    log(Log.Message(level: level, message: message, meta: meta, sampleRate: sampleRate))
  }

  func trace(_ message: String, meta: Log.Meta? = nil, sampleRate: Log.SampleRate? = nil) {
    log(.trace, message, meta: meta, sampleRate: sampleRate)
  }

  func debug(_ message: String, meta: Log.Meta? = nil, sampleRate: Log.SampleRate? = nil) {
    log(.debug, message, meta: meta, sampleRate: sampleRate)
  }

  func info(_ message: String, meta: Log.Meta? = nil, sampleRate: Log.SampleRate? = nil) {
    log(.info, message, meta: meta, sampleRate: sampleRate)
  }

  func notice(_ message: String, meta: Log.Meta? = nil, sampleRate: Log.SampleRate? = nil) {
    log(.notice, message, meta: meta, sampleRate: sampleRate)
  }

  func warn(_ message: String, meta: Log.Meta? = nil, sampleRate: Log.SampleRate? = nil) {
    log(.warn, message, meta: meta, sampleRate: sampleRate)
  }

  func error(_ message: String, meta: Log.Meta? = nil, sampleRate: Log.SampleRate? = nil) {
    log(.error, message, meta: meta, sampleRate: sampleRate)
  }

  func error(
    _ error: Error,
    _ message: String,
    meta: Log.Meta? = nil,
    sampleRate: Log.SampleRate? = nil
  ) {
    let meta = meta ?? [:]
    log(
      .error,
      message,
      meta: meta + [
        "error.swift_type": .string(String(describing: error.self)),
        "error.debug_description": .string(String(describing: error)),
      ],
      sampleRate: sampleRate
    )
  }
}
