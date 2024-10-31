public enum FilterState {
  /// a representation of the filter state omitting times for temporary states
  public enum WithoutTimes: String {
    case on
    case off
    case suspended
    case downtime
    case downtimePaused
  }

  /// a representation of the filter state suitable
  /// for exposing to the parent/child in some UI
  /// with expiration times represented in natural
  /// language relative time, i.e. "resuming in 5 minutes"
  public enum WithRelativeTimes {
    case off
    case on
    case suspended(resuming: String)
    case downtime(ending: String)
    case downtimePaused(resuming: String)

    public var isSuspended: Bool {
      switch self {
      case .suspended:
        return true
      case .off, .on, .downtime, .downtimePaused:
        return false
      }
    }
  }
}

public extension FilterState.WithRelativeTimes {
  var withoutTimes: FilterState.WithoutTimes {
    switch self {
    case .off:
      return .off
    case .on:
      return .on
    case .suspended:
      return .suspended
    case .downtime:
      return .downtime
    case .downtimePaused:
      return .downtimePaused
    }
  }
}

extension FilterState.WithoutTimes: Codable, CaseIterable, Equatable, Sendable {}
extension FilterState.WithRelativeTimes: Equatable, Sendable {}
