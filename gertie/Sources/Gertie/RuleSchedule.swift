import Foundation

public struct RuleSchedule {
  public var mode: Mode
  public var days: Days
  public var window: PlainTimeWindow

  public init(mode: Mode, days: Days, window: PlainTimeWindow) {
    self.mode = mode
    self.days = days
    self.window = window
  }
}

public extension RuleSchedule {
  func active(at date: Date, in calendar: Calendar = .current) -> Bool {
    if self.days.contains(date, in: calendar) {
      return self.window.contains(date, in: calendar) ? self.mode.isActive : !self.mode.isActive
    } else {
      return !self.mode.isActive
    }
  }
}

public extension RuleSchedule {
  enum Mode: String {
    case active
    case inactive
  }
}

public extension RuleSchedule {
  struct Days {
    public var sunday: Bool
    public var monday: Bool
    public var tuesday: Bool
    public var wednesday: Bool
    public var thursday: Bool
    public var friday: Bool
    public var saturday: Bool

    public init(
      sunday: Bool,
      monday: Bool,
      tuesday: Bool,
      wednesday: Bool,
      thursday: Bool,
      friday: Bool,
      saturday: Bool
    ) {
      self.sunday = sunday
      self.monday = monday
      self.tuesday = tuesday
      self.wednesday = wednesday
      self.thursday = thursday
      self.friday = friday
      self.saturday = saturday
    }
  }
}

public extension RuleSchedule.Days {
  static let all = RuleSchedule.Days(
    sunday: true,
    monday: true,
    tuesday: true,
    wednesday: true,
    thursday: true,
    friday: true,
    saturday: true
  )

  static let weekdays = RuleSchedule.Days(
    sunday: false,
    monday: true,
    tuesday: true,
    wednesday: true,
    thursday: true,
    friday: true,
    saturday: false
  )

  func contains(_ date: Date, in calendar: Calendar = .current) -> Bool {
    let day = calendar.component(.weekday, from: date)
    switch day {
    case 1: return self.sunday
    case 2: return self.monday
    case 3: return self.tuesday
    case 4: return self.wednesday
    case 5: return self.thursday
    case 6: return self.friday
    case 7: return self.saturday
    default: return false
    }
  }
}

extension RuleSchedule.Mode {
  var isActive: Bool {
    self == .active
  }
}

// conformances

extension RuleSchedule: Sendable, Equatable, Codable, Hashable {}
extension RuleSchedule.Mode: Sendable, Equatable, Codable, Hashable {}
extension RuleSchedule.Days: Sendable, Equatable, Codable, Hashable {}

// test/debug helpers

#if DEBUG
  public enum Weekday: Int {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
  }

  public extension RuleSchedule.Days {
    static func only(_ days: Weekday...) -> RuleSchedule.Days {
      RuleSchedule.Days(
        sunday: days.contains(.sunday),
        monday: days.contains(.monday),
        tuesday: days.contains(.tuesday),
        wednesday: days.contains(.wednesday),
        thursday: days.contains(.thursday),
        friday: days.contains(.friday),
        saturday: days.contains(.saturday)
      )
    }
  }

  public extension Date {
    static func day(_ day: Weekday, at time: String) -> Date {
      let calendar = Calendar.current
      let plainTime = PlainTime(stringLiteral: time)
      let date = calendar.nextDate(
        after: .init(),
        matching: DateComponents(weekday: day.rawValue),
        matchingPolicy: .strict,
        direction: .backward
      )!
      assert(calendar.component(.weekday, from: date) == day.rawValue)
      return calendar.date(
        bySettingHour: plainTime.hour,
        minute: plainTime.minute,
        second: 0,
        of: date
      )!
    }
  }
#endif
