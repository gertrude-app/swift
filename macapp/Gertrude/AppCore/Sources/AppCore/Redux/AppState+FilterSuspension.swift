import Foundation
import Shared
import TaggedTime

class RequestFilterSuspensionWindowState {
  enum Duration: String, Hashable, CaseIterable, Identifiable, Equatable {
    case threeMinutes = "3 minutes"
    case fiveMinutes = "5 minutes"
    case tenMinutes = "10 minutes"
    case twentyMinutes = "20 minutes"
    case thirtyMinutes = "30 minutes"
    case sixtyMinutes = "1 hour"
    case ninetyMinutes = "1.5 hours"
    case twoHours = "2 hours"
    case custom = "custom duration..."

    var id: String { rawValue }
  }

  var duration = Duration.fiveMinutes
  var comment = ""
  var customDuration = ""
  var fetchState = FetchState<Void>.waiting

  var durationSeconds: Seconds<Int> {
    switch duration {
    case .threeMinutes:
      return .init(rawValue: 60 * 3)
    case .fiveMinutes:
      return .init(rawValue: 60 * 5)
    case .tenMinutes:
      return .init(rawValue: 60 * 10)
    case .twentyMinutes:
      return .init(rawValue: 60 * 20)
    case .thirtyMinutes:
      return .init(rawValue: 60 * 30)
    case .sixtyMinutes:
      return .init(rawValue: 60 * 60)
    case .ninetyMinutes:
      return .init(rawValue: 60 * 90)
    case .twoHours:
      return .init(rawValue: 60 * 120)
    case .custom:
      guard let seconds = Int(customDuration), seconds > 0 else {
        return .init(rawValue: 60 * 5)
      }
      return .init(rawValue: seconds)
    }
  }

  init() {}
}

// protocols

extension RequestFilterSuspensionWindowState: Equatable {
  static func == (
    lhs: RequestFilterSuspensionWindowState,
    rhs: RequestFilterSuspensionWindowState
  ) -> Bool {
    if lhs.duration != rhs.duration {
      return false
    }
    if lhs.comment != rhs.comment {
      return false
    }
    if lhs.customDuration != rhs.customDuration {
      return false
    }
    if lhs.fetchState != rhs.fetchState {
      return false
    }
    return true
  }
}
