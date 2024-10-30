import ConcurrencyExtras
import XCTest
import XExpect

@testable import LibFilter

final class FilterProxyTests: XCTestCase {
  func testReadsRulesInHeartbeat() {
    let invocations = LockIsolated(0)
    let manager = FilterProxy(rules: []) {
      invocations.withValue { $0 += 1 }
      return [.urlContains("lol")]
    }

    expect(manager.rules).toEqual([])
    XCTAssertEqual(invocations.value, 0)
    manager.receiveHeartbeat()
    expect(invocations.value).toEqual(1)
    expect(manager.rules).toEqual([.urlContains("lol")])
    manager.receiveHeartbeat()
    manager.receiveHeartbeat()
    manager.receiveHeartbeat()
    expect(invocations.value).toEqual(4)
  }

  func testReadsRulesOnStart() {
    let loadRulesCalled = LockIsolated(0)
    let manager = FilterProxy(rules: []) {
      loadRulesCalled.withValue { $0 += 1 }
      return [.urlContains("lol")]
    }

    expect(loadRulesCalled.value).toEqual(0)
    expect(manager.rules).toEqual([])

    manager.startFilter()

    expect(loadRulesCalled.value).toEqual(1)
    expect(manager.rules).toEqual([.urlContains("lol")])
  }

  func testHandleRulesChangesCausesReadRules() {
    let loadRulesCalled = LockIsolated(0)
    let manager = FilterProxy(rules: []) {
      loadRulesCalled.withValue { $0 += 1 }
      return [.urlContains("lol")]
    }

    expect(loadRulesCalled.value).toEqual(0)
    expect(manager.rules).toEqual([])

    manager.handleRulesChanged()
    expect(loadRulesCalled.value).toEqual(1)
    expect(manager.rules).toEqual([.urlContains("lol")])
  }

  func testReadRulesFailureRecordsErrAndKeepsOldRules() {
    let manager = FilterProxy(rules: [.urlContains("old")]) { nil } // <- no rules
    expect(manager.rules).toEqual([.urlContains("old")])
    manager.receiveHeartbeat()
    expect(manager.rules).toEqual([.urlContains("old")])
  }
}
