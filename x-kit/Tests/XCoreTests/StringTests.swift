import XCore
import XCTest

final class StringTests: XCTestCase {
  func testSnakeCased() throws {
    XCTAssertEqual("fooBarBaz".snakeCased, "foo_bar_baz")
  }

  func testShoutyCased() throws {
    XCTAssertEqual("fooBarBaz".shoutyCased, "FOO_BAR_BAZ")
  }

  func testRegexReplace() {
    XCTAssertEqual("foobar".regexReplace("^foo", "jim"), "jimbar")
  }

  func testRegexRemove() {
    XCTAssertEqual("foobar".regexRemove("^foo"), "bar")
  }

  func testMatchesRegex() {
    XCTAssertEqual("foobar".matchesRegex("^foo"), true)
    XCTAssertEqual("foobar".matchesRegex("bar$"), true)
    XCTAssertEqual("foobar".matchesRegex("^bar"), false)
  }

  func testPadLeft() {
    XCTAssertEqual("foo".padLeft(toLength: 6, withPad: "_"), "___foo")
    XCTAssertEqual("foo".padLeft(toLength: 8, withPad: "*"), "*****foo")
  }
}
