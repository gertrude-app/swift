import Foundation
import Gertie
import XCTest
import XExpect

struct ContainsTest {
  let mode: RuleSchedule.Mode
  let days: RuleSchedule.Days
  let window: PlainTimeWindow
  let testDate: Date
  let contained: Bool
}

final class RuleScheduleTests: XCTestCase {
  func testScheduleActive() {
    let cases: [(RuleSchedule, [(test: Date, active: Bool)])] = [
      (
        RuleSchedule(mode: .active, days: .all, window: "09:00-11:00"),
        [
          (test: .day(.monday, at: "08:59"), active: false),
          (test: .day(.monday, at: "09:00"), active: true),
          (test: .day(.monday, at: "09:47"), active: true),
          (test: .day(.monday, at: "10:59"), active: true),
          (test: .day(.monday, at: "11:00"), active: false),
          (test: .day(.monday, at: "21:32"), active: false),
        ],
      ),
      (
        RuleSchedule(mode: .inactive, days: .all, window: "09:00-11:00"),
        [
          (test: .day(.monday, at: "08:59"), active: true),
          (test: .day(.monday, at: "09:00"), active: false),
          (test: .day(.monday, at: "09:47"), active: false),
          (test: .day(.monday, at: "10:59"), active: false),
          (test: .day(.monday, at: "11:00"), active: true),
          (test: .day(.monday, at: "21:32"), active: true),
        ],
      ),
      (
        RuleSchedule(mode: .active, days: .weekdays, window: "09:00-11:00"),
        [
          (test: .day(.thursday, at: "08:59"), active: false),
          (test: .day(.tuesday, at: "09:00"), active: true),
          (test: .day(.friday, at: "09:47"), active: true),
          (test: .day(.monday, at: "10:59"), active: true),
          (test: .day(.monday, at: "11:00"), active: false),
          (test: .day(.monday, at: "21:32"), active: false),
          (test: .day(.saturday, at: "08:59"), active: false),
          (test: .day(.saturday, at: "09:00"), active: false),
          (test: .day(.saturday, at: "09:47"), active: false),
          (test: .day(.saturday, at: "10:59"), active: false),
          (test: .day(.saturday, at: "11:00"), active: false),
          (test: .day(.saturday, at: "21:32"), active: false),
          (test: .day(.sunday, at: "08:59"), active: false),
          (test: .day(.sunday, at: "09:00"), active: false),
          (test: .day(.sunday, at: "09:47"), active: false),
          (test: .day(.sunday, at: "10:59"), active: false),
          (test: .day(.sunday, at: "11:00"), active: false),
          (test: .day(.sunday, at: "21:32"), active: false),
        ],
      ),
      (
        RuleSchedule(mode: .inactive, days: .only(.thursday), window: "22:31-22:34"),
        [
          (test: .day(.thursday, at: "22:30"), active: true),
          (test: .day(.thursday, at: "22:32"), active: false),
          (test: .day(.thursday, at: "22:34"), active: true),
          (test: .day(.friday, at: "22:30"), active: true),
          (test: .day(.friday, at: "22:32"), active: true),
          (test: .day(.friday, at: "22:34"), active: true),
          (test: .day(.sunday, at: "22:30"), active: true),
          (test: .day(.sunday, at: "22:32"), active: true),
          (test: .day(.sunday, at: "22:34"), active: true),
        ],
      ),
    ]
    for (schedule, tests) in cases {
      for (date, expected) in tests {
        expect(schedule.active(at: date)).toEqual(expected)
      }
    }
  }
}
