import Foundation

public struct KeychainSchedule {
  public var mode: Mode
  public var days: Days
  public var window: PlainTimeWindow

  public init(mode: Mode, days: Days, window: PlainTimeWindow) {
    self.mode = mode
    self.days = days
    self.window = window
  }
}

public extension KeychainSchedule {
  func active(at date: Date, in calendar: Calendar = .current) -> Bool {
    if self.days.contains(date, in: calendar) {
      return self.window.contains(date, in: calendar) ? self.mode.isActive : !self.mode.isActive
    } else {
      return !self.mode.isActive
    }
  }
}

public extension KeychainSchedule {
  enum Mode: String {
    case active
    case inactive
  }

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

public extension KeychainSchedule.Days {
  static let all = KeychainSchedule.Days(
    sunday: true,
    monday: true,
    tuesday: true,
    wednesday: true,
    thursday: true,
    friday: true,
    saturday: true
  )

  static let weekdays = KeychainSchedule.Days(
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
    case 1: return sunday
    case 2: return monday
    case 3: return tuesday
    case 4: return wednesday
    case 5: return thursday
    case 6: return friday
    case 7: return saturday
    default: return false
    }
  }
}

extension KeychainSchedule.Mode {
  var isActive: Bool {
    self == .active
  }
}

// conformances

extension KeychainSchedule: Sendable, Equatable, Codable {}
extension KeychainSchedule.Mode: Sendable, Equatable, Codable {}
extension KeychainSchedule.Days: Sendable, Equatable, Codable {}

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

  public extension KeychainSchedule.Days {
    static func only(_ days: Weekday...) -> KeychainSchedule.Days {
      KeychainSchedule.Days(
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
