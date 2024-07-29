import XCTest

@testable import Api

class CoalesceMonitoringItemsTests: XCTestCase {
  func testAlternatingItemsDontCoalesce() {
    var screenshot1 = Screenshot.random
    screenshot1.createdAt = Date(timeIntervalSince1970: 0)
    var keystroke1 = KeystrokeLine.random
    keystroke1.createdAt = Date(timeIntervalSince1970: 10)
    var screenshot2 = Screenshot.random
    screenshot2.createdAt = Date(timeIntervalSince1970: 20)
    var keystroke2 = KeystrokeLine.random
    keystroke2.createdAt = Date(timeIntervalSince1970: 30)

    let coalesced = coalesce([screenshot2, screenshot1], [keystroke2, keystroke1])

    XCTAssertEqual(coalesced.count, 4)
    XCTAssertEqual(coalesced[0].keystrokeLine?.ids, [keystroke2.id])
    XCTAssertEqual(coalesced[1].screenshot?.id, screenshot2.id)
    XCTAssertEqual(coalesced[2].keystrokeLine?.ids, [keystroke1.id])
    XCTAssertEqual(coalesced[3].screenshot?.id, screenshot1.id)
  }

  func testContiguousKeystrokesFromSameAppCoalesce() {
    var screenshot1 = Screenshot.random
    screenshot1.createdAt = Date(timeIntervalSince1970: 0)

    // contigous keystrokes from same app
    var keystroke1 = KeystrokeLine.random
    keystroke1.appName = "Brave"
    keystroke1.line = "Foo"
    keystroke1.createdAt = Date(timeIntervalSince1970: 10)
    var keystroke2 = KeystrokeLine.random
    keystroke2.appName = "Brave"
    keystroke2.line = "Bar"
    keystroke2.createdAt = Date(timeIntervalSince1970: 15)

    var screenshot2 = Screenshot.random
    screenshot2.createdAt = Date(timeIntervalSince1970: 20)

    let coalesced = coalesce([screenshot2, screenshot1], [keystroke2, keystroke1])

    XCTAssertEqual(coalesced.count, 3)
    XCTAssertEqual(coalesced[0].screenshot?.id, screenshot2.id)
    XCTAssertEqual(coalesced[1].keystrokeLine?.ids, [keystroke2.id, keystroke1.id])
    XCTAssertEqual(coalesced[2].screenshot?.id, screenshot1.id)
    XCTAssertEqual(coalesced[1].keystrokeLine?.line, "Foo\nBar")
  }

  func testCoalescedIsDuringSuspensionIfAnyDuringSuspension() {
    var keystroke1 = KeystrokeLine.random
    keystroke1.appName = "Brave"
    keystroke1.line = "Foo"
    keystroke1.filterSuspended = false
    keystroke1.createdAt = Date(timeIntervalSince1970: 10)
    var keystroke2 = KeystrokeLine.random
    keystroke2.appName = "Brave"
    keystroke2.line = "Bar"
    keystroke2.filterSuspended = true // <-- only one during suspension
    keystroke2.createdAt = Date(timeIntervalSince1970: 12)
    var keystroke3 = KeystrokeLine.random
    keystroke3.appName = "Brave"
    keystroke3.line = "Bar"
    keystroke3.filterSuspended = false
    keystroke3.createdAt = Date(timeIntervalSince1970: 15)

    let coalesced = coalesce([], [keystroke2, keystroke1, keystroke3])

    XCTAssertEqual(coalesced.count, 1)
    XCTAssertEqual(coalesced[0].keystrokeLine?.ids.count, 3)
    XCTAssertEqual(coalesced[0].keystrokeLine?.duringSuspension, true)
  }

  func testDoesntCoalesceDeletedAndNonDeleted() {
    var keystroke1 = KeystrokeLine.random
    keystroke1.appName = "Brave"
    keystroke1.createdAt = Date(timeIntervalSince1970: 10)
    keystroke1.deletedAt = Date(timeIntervalSince1970: 11) // deleted
    var keystroke2 = KeystrokeLine.random
    keystroke2.appName = "Brave"
    keystroke2.createdAt = Date(timeIntervalSince1970: 15)
    keystroke2.deletedAt = nil // not deleted
    var keystroke3 = KeystrokeLine.random
    keystroke3.appName = "Brave"
    keystroke3.createdAt = Date(timeIntervalSince1970: 20)
    keystroke3.deletedAt = Date(timeIntervalSince1970: 21) // deleted

    let coalesced = coalesce([], [keystroke2, keystroke1, keystroke3])

    XCTAssertEqual(coalesced.count, 3)
  }

  func testContiguousKeystrokesFromDifferentAppsDontCoalesce() {
    var screenshot1 = Screenshot.random
    screenshot1.createdAt = Date(timeIntervalSince1970: 0)

    // contigous keystrokes from DIFFERENT app
    var keystroke1 = KeystrokeLine.random
    keystroke1.appName = "Brave"
    keystroke1.createdAt = Date(timeIntervalSince1970: 10)
    var keystroke2 = KeystrokeLine.random
    keystroke2.appName = "Xcode"
    keystroke2.createdAt = Date(timeIntervalSince1970: 15)

    var screenshot2 = Screenshot.random
    screenshot2.createdAt = Date(timeIntervalSince1970: 20)

    let coalesced = coalesce([screenshot2, screenshot1], [keystroke2, keystroke1])

    XCTAssertEqual(coalesced.count, 4)
    XCTAssertEqual(coalesced[0].screenshot?.id, screenshot2.id)
    XCTAssertEqual(coalesced[1].keystrokeLine?.ids, [keystroke2.id])
    XCTAssertEqual(coalesced[2].keystrokeLine?.ids, [keystroke1.id])
    XCTAssertEqual(coalesced[3].screenshot?.id, screenshot1.id)
  }
}
