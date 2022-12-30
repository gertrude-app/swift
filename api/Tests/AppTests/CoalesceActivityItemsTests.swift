import XCTest

@testable import App

class CoalesceMonitoringItemsTests: XCTestCase {
  func testAlternatingItemsDontCoalesce() {
    let screenshot1 = Screenshot.random
    screenshot1.createdAt = Date(timeIntervalSince1970: 0)
    let keystroke1 = KeystrokeLine.random
    keystroke1.createdAt = Date(timeIntervalSince1970: 10)
    let screenshot2 = Screenshot.random
    screenshot2.createdAt = Date(timeIntervalSince1970: 20)
    let keystroke2 = KeystrokeLine.random
    keystroke2.createdAt = Date(timeIntervalSince1970: 30)

    let coalesced = coalesce([screenshot2, screenshot1], [keystroke2, keystroke1])

    XCTAssertEqual(coalesced.count, 4)
    XCTAssertEqual(coalesced[0].b?.ids, [keystroke2.id])
    XCTAssertEqual(coalesced[1].a?.id, screenshot2.id)
    XCTAssertEqual(coalesced[2].b?.ids, [keystroke1.id])
    XCTAssertEqual(coalesced[3].a?.id, screenshot1.id)
  }

  func testContiguousKeystrokesFromSameAppCoalesce() {
    let screenshot1 = Screenshot.random
    screenshot1.createdAt = Date(timeIntervalSince1970: 0)

    // contigous keystrokes from same app
    let keystroke1 = KeystrokeLine.random
    keystroke1.appName = "Brave"
    keystroke1.line = "Foo"
    keystroke1.createdAt = Date(timeIntervalSince1970: 10)
    let keystroke2 = KeystrokeLine.random
    keystroke2.appName = "Brave"
    keystroke2.line = "Bar"
    keystroke2.createdAt = Date(timeIntervalSince1970: 15)

    let screenshot2 = Screenshot.random
    screenshot2.createdAt = Date(timeIntervalSince1970: 20)

    let coalesced = coalesce([screenshot2, screenshot1], [keystroke2, keystroke1])

    XCTAssertEqual(coalesced.count, 3)
    XCTAssertEqual(coalesced[0].a?.id, screenshot2.id)
    XCTAssertEqual(coalesced[1].b?.ids, [keystroke2.id, keystroke1.id])
    XCTAssertEqual(coalesced[2].a?.id, screenshot1.id)
    XCTAssertEqual(coalesced[1].b?.line, "Foo\nBar")
  }

  func testContiguousKeystrokesFromDifferentAppsDontCoalesce() {
    let screenshot1 = Screenshot.random
    screenshot1.createdAt = Date(timeIntervalSince1970: 0)

    // contigous keystrokes from DIFFERENT app
    let keystroke1 = KeystrokeLine.random
    keystroke1.appName = "Brave"
    keystroke1.createdAt = Date(timeIntervalSince1970: 10)
    let keystroke2 = KeystrokeLine.random
    keystroke2.appName = "Xcode"
    keystroke2.createdAt = Date(timeIntervalSince1970: 15)

    let screenshot2 = Screenshot.random
    screenshot2.createdAt = Date(timeIntervalSince1970: 20)

    let coalesced = coalesce([screenshot2, screenshot1], [keystroke2, keystroke1])

    XCTAssertEqual(coalesced.count, 4)
    XCTAssertEqual(coalesced[0].a?.id, screenshot2.id)
    XCTAssertEqual(coalesced[1].b?.ids, [keystroke2.id])
    XCTAssertEqual(coalesced[2].b?.ids, [keystroke1.id])
    XCTAssertEqual(coalesced[3].a?.id, screenshot1.id)
  }
}
