import DuetSQL
import XCTest
import XExpect

final class PostgresTests: XCTestCase {
  func testStringApostrophesEscaped() {
    let string = Postgres.Data.string("don't")
    expect(string.param).toEqual("'don''t'")
  }
}
