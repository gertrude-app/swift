import Foundation

public enum FilterState {
  /// a representation of the filter state omitting times for temporary states
  public enum WithoutTimes: String {
    case on
    case off
    case suspended
    case downtime
    case downtimePaused
  }

  /// a representation of the filter state with times for temporary states
  public enum WithTimes {
    case on
    case off
    case suspended(resuming: Date)
    case downtime(ending: Date)
    case downtimePaused(resuming: Date)
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
  }
}

// extensions

public extension FilterState.WithTimes {
  func withRelativeTimes(from now: Date = .init()) -> FilterState.WithRelativeTimes {
    switch self {
    case .off:
      .off
    case .on:
      .on
    case .suspended(resuming: let date):
      .suspended(resuming: now.timeRemaining(until: date))
    case .downtime(ending: let date):
      .downtime(ending: now.timeRemaining(until: date))
    case .downtimePaused(resuming: let date):
      .downtimePaused(resuming: now.timeRemaining(until: date))
    }
  }
}

public extension FilterState.WithRelativeTimes {
  var isSuspended: Bool {
    switch self {
    case .suspended:
      true
    case .off, .on, .downtime, .downtimePaused:
      false
    }
  }

  var withoutTimes: FilterState.WithoutTimes {
    switch self {
    case .off:
      .off
    case .on:
      .on
    case .suspended:
      .suspended
    case .downtime:
      .downtime
    case .downtimePaused:
      .downtimePaused
    }
  }
}

extension FilterState.WithoutTimes: Codable, CaseIterable, Equatable, Sendable {}
extension FilterState.WithRelativeTimes: Equatable, Sendable {}
extension FilterState.WithTimes: Equatable, Codable, Sendable {}
