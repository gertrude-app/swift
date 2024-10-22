import Gertie
import XCTest
import XExpect

final class TimeTests: XCTestCase {
  func testPlainTimeMinutesUntil() {
    let cases: [(test: String, reference: String, expected: Int)] = [
      (test: "12:00", reference: "12:00", expected: 0),
      (test: "12:00", reference: "12:01", expected: 1),
      (test: "12:01", reference: "12:00", expected: 1439),
      (test: "00:00", reference: "00:00", expected: 0),
      (test: "00:00", reference: "00:01", expected: 1),
      (test: "00:01", reference: "00:00", expected: 1439),
      (test: "23:59", reference: "00:01", expected: 2),
      (test: "00:00", reference: "00:05", expected: 5),
      (test: "05:00", reference: "05:05", expected: 5),
      (test: "05:00", reference: "05:05", expected: 5),
    ]
    for (test, reference, expected) in cases {
      let testTime = PlainTime(stringLiteral: test)
      let referenceTime = PlainTime(stringLiteral: reference)
      expect(testTime.minutesUntil(referenceTime)).toEqual(expected)
    }
  }

  func testPlainTimeWindowContains_NotCrossingMidnight() {
    let window: PlainTimeWindow = "17:00-18:00" // 5pm to 6pm
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
      expect(window.contains(date, in: .current)).toEqual(expected)
    }
  }

  func testPlainTimeWindowContains_CrossingMidnight() {
    let window: PlainTimeWindow = "22:00-02:00" // 10pm to 2am
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
      expect(window.contains(date, in: .current)).toEqual(expected)
    }
  }

  func testPlainTimeWindowContains_NonHourBoundaries() {
    let window: PlainTimeWindow = "17:30-18:20" // 5:30pm to 6:20pm
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
      expect(window.contains(date, in: .current)).toEqual(expected)
    }
  }

  func testPlainTimeWindowContains_NonHourBoundaries_CrossingMidnight() {
    let window: PlainTimeWindow = "22:30-02:20" // 10:30pm to 2:20am
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
      expect(window.contains(date, in: .current)).toEqual(expected)
    }
  }
}
