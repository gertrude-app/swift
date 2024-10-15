import Gertie
import XCTest
import XExpect

final class TimeTests: XCTestCase {
  func testPlainTimeWindowContains_NotCrossingMidnight() {
    let downtime = PlainTimeWindow( // 5pm to 6pm
      start: .init(hour: 17, minute: 0),
      end: .init(hour: 18, minute: 0)
    )
    let cases: [(hour: Int, minute: Int, expected: Bool)] = [
      (hour: 12, minute: 10, expected: false),
      (hour: 16, minute: 59, expected: false),
      (hour: 17, minute: 00, expected: true),
      (hour: 17, minute: 01, expected: true),
      (hour: 17, minute: 23, expected: true),
      (hour: 17, minute: 59, expected: true),
      (hour: 18, minute: 00, expected: false),
      (hour: 22, minute: 44, expected: false),
      (hour: 06, minute: 14, expected: false),
    ]
    for (hour, minute, expected) in cases {
      let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute))!
      expect(downtime.contains(date, in: .current)).toEqual(expected)
    }
  }

  func testPlainTimeWindowContains_CrossingMidnight() {
    let downtime = PlainTimeWindow( // 10pm to 2am
      start: .init(hour: 22, minute: 00),
      end: .init(hour: 02, minute: 00)
    )
    let cases: [(hour: Int, minute: Int, expected: Bool)] = [
      (hour: 11, minute: 38, expected: false),
      (hour: 21, minute: 59, expected: false),
      (hour: 22, minute: 00, expected: true),
      (hour: 22, minute: 01, expected: true),
      (hour: 23, minute: 59, expected: true),
      (hour: 00, minute: 00, expected: true),
      (hour: 00, minute: 01, expected: true),
      (hour: 01, minute: 59, expected: true),
      (hour: 02, minute: 00, expected: false),
      (hour: 02, minute: 01, expected: false),
      (hour: 03, minute: 59, expected: false),
      (hour: 05, minute: 16, expected: false),
    ]
    for (hour, minute, expected) in cases {
      let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute))!
      expect(downtime.contains(date, in: .current)).toEqual(expected)
    }
  }

  func testPlainTimeWindowContains_NonHourBoundaries() {
    let downtime = PlainTimeWindow( // 5:30pm to 6:20pm
      start: .init(hour: 17, minute: 30),
      end: .init(hour: 18, minute: 20)
    )
    let cases: [(hour: Int, minute: Int, expected: Bool)] = [
      (hour: 13, minute: 11, expected: false),
      (hour: 16, minute: 59, expected: false),
      (hour: 17, minute: 00, expected: false),
      (hour: 17, minute: 29, expected: false),
      (hour: 17, minute: 30, expected: true),
      (hour: 18, minute: 00, expected: true),
      (hour: 18, minute: 01, expected: true),
      (hour: 18, minute: 19, expected: true),
      (hour: 18, minute: 20, expected: false),
      (hour: 23, minute: 01, expected: false),
    ]
    for (hour, minute, expected) in cases {
      let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute))!
      expect(downtime.contains(date, in: .current)).toEqual(expected)
    }
  }

  func testPlainTimeWindowContains_NonHourBoundaries_CrossingMidnight() {
    let downtime = PlainTimeWindow( // 10:30pm to 2:20am
      start: .init(hour: 22, minute: 30),
      end: .init(hour: 02, minute: 20)
    )
    let cases: [(hour: Int, minute: Int, expected: Bool)] = [
      (hour: 21, minute: 59, expected: false),
      (hour: 22, minute: 00, expected: false),
      (hour: 22, minute: 29, expected: false),
      (hour: 22, minute: 30, expected: true),
      (hour: 23, minute: 59, expected: true),
      (hour: 00, minute: 00, expected: true),
      (hour: 00, minute: 01, expected: true),
      (hour: 01, minute: 59, expected: true),
      (hour: 02, minute: 00, expected: true),
      (hour: 02, minute: 01, expected: true),
      (hour: 02, minute: 19, expected: true),
      (hour: 02, minute: 20, expected: false),
      (hour: 02, minute: 21, expected: false),
      (hour: 03, minute: 59, expected: false),
      (hour: 12, minute: 33, expected: false),
    ]
    for (hour, minute, expected) in cases {
      let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute))!
      expect(downtime.contains(date, in: .current)).toEqual(expected)
    }
  }
}
