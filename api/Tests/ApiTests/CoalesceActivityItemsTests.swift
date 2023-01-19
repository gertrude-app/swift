import XCTest

@testable import Api

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
    XCTAssertEqual(coalesced[0].t2?.ids, [keystroke2.id])
    XCTAssertEqual(coalesced[1].t1?.id, screenshot2.id)
    XCTAssertEqual(coalesced[2].t2?.ids, [keystroke1.id])
    XCTAssertEqual(coalesced[3].t1?.id, screenshot1.id)
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
    XCTAssertEqual(coalesced[0].t1?.id, screenshot2.id)
    XCTAssertEqual(coalesced[1].t2?.ids, [keystroke2.id, keystroke1.id])
    XCTAssertEqual(coalesced[2].t1?.id, screenshot1.id)
    XCTAssertEqual(coalesced[1].t2?.line, "Foo\nBar")
  }

  func testDoesntCoalesceDeletedAndNonDeleted() {
    let keystroke1 = KeystrokeLine.random
    keystroke1.appName = "Brave"
    keystroke1.createdAt = Date(timeIntervalSince1970: 10)
    keystroke1.deletedAt = Date(timeIntervalSince1970: 11) // deleted
    let keystroke2 = KeystrokeLine.random
    keystroke2.appName = "Brave"
    keystroke2.createdAt = Date(timeIntervalSince1970: 15)
    keystroke2.deletedAt = nil // not deleted
    let keystroke3 = KeystrokeLine.random
    keystroke3.appName = "Brave"
    keystroke3.createdAt = Date(timeIntervalSince1970: 20)
    keystroke3.deletedAt = Date(timeIntervalSince1970: 21) // deleted

    let coalesced = coalesce([], [keystroke2, keystroke1, keystroke3])

    XCTAssertEqual(coalesced.count, 3)
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
    XCTAssertEqual(coalesced[0].t1?.id, screenshot2.id)
    XCTAssertEqual(coalesced[1].t2?.ids, [keystroke2.id])
    XCTAssertEqual(coalesced[2].t2?.ids, [keystroke1.id])
    XCTAssertEqual(coalesced[3].t1?.id, screenshot1.id)
  }
}
