import SharedCore
import XCTest

@testable import FilterCore

class DecisionBagTests: XCTestCase {

  var decision: FilterDecision {
    FilterDecision(
      verdict: .block,
      reason: .defaultNotAllowed,
      filterFlow: .init()
    )
  }

  func testTwoIdenticalDecisions() throws {
    let bag = DecisionBag()
    bag.push(decision)
    bag.push(decision)
    XCTAssertEqual(1, bag.count)
    let decisions = bag.flushRecentFirst()
    XCTAssertEqual(2, decisions.first!.count)
  }

  func testDecisionsWithFullUrlAndIdenticalExceptIpAddressShouldBeMerged() throws {
    var decision1 = decision
    decision1.filterFlow!.url = "https://somesite.com/path?q=123"
    decision1.filterFlow!.ipAddress = "1.2.3.4"
    var decision2 = decision
    decision2.filterFlow!.url = "https://somesite.com/path?q=123"
    decision2.filterFlow!.ipAddress = "3.4.5.6"
    let bag = DecisionBag()
    bag.push(decision1)
    bag.push(decision2)
    XCTAssertEqual(1, bag.count)
  }

  func testTwoNonIdenticalDecisions() throws {
    let bag = DecisionBag()
    bag.push(decision)
    var decision2 = decision
    decision2.verdict = .allow
    decision2.reason = .fromGertrudeApp
    bag.push(decision2)
    XCTAssertEqual(2, bag.count)
    let decisions = bag.flushRecentFirst()
    XCTAssertEqual(1, decisions.first!.count)
    XCTAssertEqual(1, decisions.last!.count)
  }
}
