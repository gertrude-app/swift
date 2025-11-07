import Logging

extension Logger {
  static let null = Logger(label: "(null)", factory: { _ in NullHandler() })
}

private struct NullHandler: LogHandler {
  public func log(
    level: Logger.Level,
    message: Logger.Message,
    metadata: Logger.Metadata?,
    source: String,
    file: String,
    function: String,
    line: UInt,
  ) {}

  subscript(metadataKey _: String) -> Logger.Metadata.Value? {
    get { nil }
    set {}
  }

  var metadata: Logger.Metadata {
    get { [:] }
    set {}
  }

  var logLevel: Logger.Level {
    get { .trace }
    set {}
  }
}
