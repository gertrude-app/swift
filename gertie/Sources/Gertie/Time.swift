import Foundation

/// A wall-clock time not associated with a particular date or time zone
public struct PlainTime {
  var hour: Int
  var minute: Int

  public init(hour: Int, minute: Int) {
    self.hour = hour
    self.minute = minute
  }
}

/// A time "window" with a start and end not associated
/// with a particular date or time zone
public struct PlainTimeWindow {
  var start: PlainTime
  var end: PlainTime

  public init(start: PlainTime, end: PlainTime) {
    self.start = start
    self.end = end
  }
}

public extension PlainTimeWindow {
  var crossesMidnight: Bool {
    self.start.hour > self.end.hour
  }

  func contains(_ date: Date, in calendar: Calendar) -> Bool {
    let test = calendar.component(.hour, from: date) * 60
      + calendar.component(.minute, from: date)
    if self.crossesMidnight {
      return test >= self.start.minutesFromMidnight || test < self.end.minutesFromMidnight
    } else {
      return test >= self.start.minutesFromMidnight && test < self.end.minutesFromMidnight
    }
  }
}

extension PlainTime {
  var minutesFromMidnight: Int {
    self.hour * 60 + self.minute
  }
}

// conformances

extension PlainTime: Sendable, Equatable, Hashable, Codable {}
extension PlainTimeWindow: Sendable, Equatable, Hashable, Codable {}
