public extension Log {
  enum Level: String {
    case trace
    case debug
    case info
    case notice
    case warn
    case error
  }
}

extension Log.Level: Comparable {
  private var number: Int {
    switch self {
    case .trace:
      return 1
    case .debug:
      return 2
    case .info:
      return 3
    case .notice:
      return 4
    case .warn:
      return 5
    case .error:
      return 6
    }
  }

  public static func < (lhs: Log.Level, rhs: Log.Level) -> Bool {
    lhs.number < rhs.number
  }
}

public extension Log.Level {
  var emoji: String {
    switch self {
    case .trace:
      return "🟣"
    case .debug:
      return "🟤"
    case .info:
      return "🔵"
    case .notice:
      return "🟢"
    case .warn:
      return "🟠"
    case .error:
      return "🔴"
    }
  }
}

extension Log.Level: Codable {}
