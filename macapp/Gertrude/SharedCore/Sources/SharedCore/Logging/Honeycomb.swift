import Foundation

public enum Honeycomb {
  public struct Event: Codable {
    public var timestamp: String
    public var samplerate: Int?
    public var data: Log.Meta = [:]

    public init(
      timestamp: String = Date().isoString,
      level: Log.Level,
      message: String,
      meta: Log.Meta? = nil,
      sampleRate: Log.SampleRate? = nil
    ) {
      self.timestamp = timestamp
      samplerate = sampleRate.map(\.denominatorUnderOne)

      data = meta + [
        "log.level": .string(level.rawValue),
        "log.message": .string(message),
        "sample.fraction": .string("1/\(sampleRate?.denominatorUnderOne ?? 1)"),
      ]

      if level == .error {
        data["error"] = true
      }
    }

    public init(_ logMsg: Log.Message) {
      self.init(
        timestamp: logMsg.date.isoString,
        level: logMsg.level,
        message: logMsg.message,
        meta: logMsg.meta,
        sampleRate: logMsg.sampleRate
      )
    }

    public func addingMeta(_ meta: Log.Meta) -> Self {
      var copy = self
      copy.data.merge(meta) { _, new in new }
      return copy
    }
  }
}
