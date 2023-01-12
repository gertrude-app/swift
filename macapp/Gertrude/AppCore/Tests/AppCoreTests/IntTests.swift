import XCTest

@testable import AppCore

final class IntTests: XCTestCase {
  func testFutureHumanTime() throws {
    let cases: [(Int, String?)] = [
      (-5, nil),
      (0, nil),
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
      (60 * 10, "10 minutes from now"),
      (60 * 40, "40 minutes from now"),
      (60 * 50, "about an hour from now"),
      (60 * 60, "about an hour from now"),
      (60 * 69, "about an hour from now"),
      (60 * 70, "1 hour 10 minutes from now"),
      (60 * 90, "1 hour 30 minutes from now"),
      (60 * 119, "1 hour 59 minutes from now"),
      (60 * 60 * 2, "about 2 hours from now"),
      (60 * 60 * 5, "about 5 hours from now"),
      (60 * 60 * 36, "about 36 hours from now"),
      (60 * 60 * 47, "about 47 hours from now"),
      (60 * 60 * 48, "2 days from now"),
      (60 * 60 * 72, "3 days from now"),
    ]

    for (int, string) in cases {
      XCTAssertEqual(int.futureHumanTime, string)
    }
  }
}
