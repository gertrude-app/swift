import Shared
import XCTest
import XExpect

@testable import App

final class FilterSuspensionTests: XCTestCase {
  func testRelativeExpiration() throws {
    let cases = [
      (-5, "now"),
      (0, "now"),
      (5, "less than a minute from now"),
      (44, "less than a minute from now"),
      (45, "about a minute from now"),
      (60, "about a minute from now"),
      (83, "about a minute from now"),
      (85, "about 90 seconds from now"),
      (90, "about 90 seconds from now"),
      (99, "about 90 seconds from now"),
      (100, "about 2 minutes from now"),
      (119, "about 2 minutes from now"),
      (120, "2 minutes from now"),
      (180, "3 minutes from now"),
      (185, "3 minutes from now"),
      (60 * 5 - 31, "4 minutes from now"),
      (60 * 5 - 1, "5 minutes from now"),
      (60 * 10, "10 minutes from now"),
      (60 * 40, "40 minutes from now"),
      (60 * 50, "about an hour from now"),
      (60 * 60, "about an hour from now"),
      (60 * 69, "about an hour from now"),
      (60 * 70, "1 hour 10 minutes from now"),
      (60 * 90, "1 hour 30 minutes from now"),
      (60 * 119, "1 hour 59 minutes from now"),
      (60 * 60 * 2, "about 2 hours from now"),
      (60 * 60 * 3 - 1, "about 3 hours from now"),
      (60 * 60 * 5, "about 5 hours from now"),
      (60 * 60 * 36, "about 36 hours from now"),
      (60 * 60 * 47, "about 47 hours from now"),
      (60 * 60 * 48, "2 days from now"),
      (60 * 60 * 72, "3 days from now"),
    ]

    for (seconds, expected) in cases {
      let now = Date(timeIntervalSince1970: 100)
      let suspension = FilterSuspension(scope: .webBrowsers, duration: .init(seconds), now: now)
      expect(suspension.relativeExpiration(from: now)).toEqual(expected)
    }
  }
}
