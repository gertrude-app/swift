import Foundation

public extension Log {
  struct Message {
    public var date: Date
    public var level: Level
    public var message: String
    public var meta: Meta
    public var sampleRate: SampleRate?

    public init(
      date: Date = .init(),
      level: Log.Level = .info,
      message: String,
      meta: Log.Meta? = nil,
      sampleRate: Log.SampleRate? = nil
    ) {
      self.date = date
      self.level = level
      self.message = message
      self.meta = meta ?? [:]
      self.sampleRate = sampleRate
    }
  }
}

public extension Log.Message {
  init(
    date: Date = .init(),
    _ level: Log.Level = .info,
    _ message: String,
    _ meta: Log.Meta? = nil,
    _ sampleRate: Log.SampleRate? = nil
  ) {
    self.date = date
    self.level = level
    self.message = message
    self.meta = meta ?? [:]
    self.sampleRate = sampleRate
  }

  func addingMeta(_ meta: Log.Meta) -> Self {
    .init(
      date: date,
      level: level,
      message: message,
      meta: self.meta + meta,
      sampleRate: sampleRate
    )
  }

  static func debug(
    date: Date = .init(),
    _ message: String,
    _ meta: Log.Meta? = nil,
    _ sampleRate: Log.SampleRate? = nil
  ) -> Self {
    .init(date: date, .debug, message, meta, sampleRate)
  }

  static func warn(
    date: Date = .init(),
    _ message: String,
    _ meta: Log.Meta? = nil,
    _ sampleRate: Log.SampleRate? = nil
  ) -> Self {
    .init(date: date, .warn, message, meta, sampleRate)
  }

  static func info(
    date: Date = .init(),
    _ message: String,
    _ meta: Log.Meta? = nil,
    _ sampleRate: Log.SampleRate? = nil
  ) -> Self {
    .init(date: date, .info, message, meta, sampleRate)
  }

  static func notice(
    date: Date = .init(),
    _ message: String,
    _ meta: Log.Meta? = nil,
    _ sampleRate: Log.SampleRate? = nil
  ) -> Self {
    .init(date: date, .notice, message, meta, sampleRate)
  }

  static func error(
    date: Date = .init(),
    _ message: String,
    _ meta: Log.Meta? = nil,
    _ sampleRate: Log.SampleRate? = nil
  ) -> Self {
    .init(date: date, .error, message, meta, sampleRate)
  }
}

extension Log.Message: Codable {}
extension Log.Message: Equatable {}

infix operator |>
public func |> (lhs: String, rhs: Log.Message) -> Log.Message {
  .init(date: rhs.date, level: rhs.level, message: "\(lhs) > \(rhs.message)", meta: rhs.meta)
}
