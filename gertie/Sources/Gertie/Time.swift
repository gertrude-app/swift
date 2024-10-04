/// A wall-clock time not associated with a particular date or time zone
public struct PlainTime {
  var hour: UInt8
  var minute: UInt8

  public init(hour: UInt8, minute: UInt8) {
    self.hour = hour
    self.minute = minute
  }
}

/// A time "window"  with a start and end not
/// associated with a particular date or time zone
public struct PlainTimeWindow {
  var start: PlainTime
  var end: PlainTime

  public init(start: PlainTime, end: PlainTime) {
    self.start = start
    self.end = end
  }
}

// extensions

extension PlainTime: Sendable, Equatable, Hashable, Codable {}
extension PlainTimeWindow: Sendable, Equatable, Hashable, Codable {}
