import DuetSQL
import XCTest

final class PostgresTests: XCTestCase {
  func testStringApostrophesEscaped() {
    let string = Postgres.Data.string("don't")
    XCTAssertEqual(string.param, "'don''t'")
  }
}
