public extension Log {
  struct Config {
    public var trace: SampleRate
    public var debug: SampleRate
    public var info: SampleRate
    public var notice: SampleRate
    public var warn: SampleRate
    public var error: SampleRate

    public func rate(for level: Log.Level) -> SampleRate {
      switch level {
      case .trace: return trace
      case .debug: return debug
      case .info: return info
      case .notice: return notice
      case .warn: return warn
      case .error: return error
      }
    }

    public init(
      trace: SampleRate,
      debug: SampleRate,
      info: SampleRate,
      notice: SampleRate,
      warn: SampleRate,
      error: SampleRate
    ) {
      self.trace = trace
      self.debug = debug
      self.info = info
      self.notice = notice
      self.warn = warn
      self.error = error
    }
  }
}

extension Log.Config: Equatable {}
extension Log.Config: Codable {}

public extension Log.Config {
  static let none = Log.Config(
    trace: .none,
    debug: .none,
    info: .none,
    notice: .none,
    warn: .none,
    error: .none
  )

  static let all = Log.Config(
    trace: .all,
    debug: .all,
    info: .all,
    notice: .all,
    warn: .all,
    error: .all
  )

  static let trace = Log.Config(
    trace: .all,
    debug: .all,
    info: .all,
    notice: .all,
    warn: .all,
    error: .all
  )

  static let debug = Log.Config(
    trace: .none,
    debug: .all,
    info: .all,
    notice: .all,
    warn: .all,
    error: .all
  )

  static let info = Log.Config(
    trace: .none,
    debug: .none,
    info: .all,
    notice: .all,
    warn: .all,
    error: .all
  )

  static let notice = Log.Config(
    trace: .none,
    debug: .none,
    info: .none,
    notice: .all,
    warn: .all,
    error: .all
  )

  static let warn = Log.Config(
    trace: .none,
    debug: .none,
    info: .none,
    notice: .none,
    warn: .all,
    error: .all
  )

  static let error = Log.Config(
    trace: .none,
    debug: .none,
    info: .none,
    notice: .none,
    warn: .none,
    error: .all
  )
}
