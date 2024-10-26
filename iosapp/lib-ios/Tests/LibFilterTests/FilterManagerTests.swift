import ConcurrencyExtras
import XCTest
import XExpect

@testable import LibFilter

final class FilterManagerTests: XCTestCase {
  func testReadsRulesInHeartbeat() {
    let invocations = LockIsolated(0)
    let manager = FilterManager(rules: []) {
      invocations.withValue { $0 += 1 }
      return .success([.urlContains("lol")])
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
    let invocations = LockIsolated(0)
    let manager = FilterManager(rules: []) {
      invocations.withValue { $0 += 1 }
      return .success([.urlContains("lol")])
    }

    expect(invocations.value).toEqual(0)
    expect(manager.rules).toEqual([])

    manager.startFilter()

    expect(invocations.value).toEqual(1)
    expect(manager.rules).toEqual([.urlContains("lol")])
  }

  func testSpecialUrlTriggersReadRules() {
    let invocations = LockIsolated(0)
    let manager = FilterManager(rules: []) {
      invocations.withValue { $0 += 1 }
      return .success([.urlContains("lol")])
    }

    expect(invocations.value).toEqual(0)
    expect(manager.rules).toEqual([])

    var verdict = manager.decideFlow(
      hostname: "read-rules.gertrude.app",
      bundleId: .gertrudeBundleIdLong // <-- long bundle id
    )

    expect(verdict).toEqual(.drop)
    expect(invocations.value).toEqual(1)
    expect(manager.rules).toEqual([.urlContains("lol")])

    verdict = manager.decideFlow(
      hostname: "read-rules.gertrude.app",
      bundleId: .gertrudeBundleIdShort // <-- short (no team prefix) bundle id
    )

    expect(verdict).toEqual(.drop)
    expect(invocations.value).toEqual(2)

    verdict = manager.decideFlow(
      hostname: "read-rules.gertrude.app",
      bundleId: "com.not-matching.bundle.id" // <-- wrong bundle id
    )

    expect(verdict).toEqual(.allow)
    expect(invocations.value).toEqual(2) // <-- no new rules read
  }

  func testReadRulesErrorRecordsErrAndKeepsOldRules() {
    let manager = FilterManager(rules: [.urlContains("old")]) {
      .failure(.rulesDecodeFailed)
    }

    expect(manager.rules).toEqual([.urlContains("old")])

    manager.receiveHeartbeat()

    expect(manager.rules).toEqual([.urlContains("old")])
    expect(manager.errors).toEqual([.rulesDecodeFailed])
  }

  func testAllowErrorFlows() {
    let manager = FilterManager { .success([]) }

    var verdict = manager.decideFlow(
      url: "https://api.gertrude.com/ios-filter-errors-v1/no-rules-found/vendor-id",
      bundleId: .gertrudeBundleIdShort
    )
    expect(verdict).toEqual(.drop) // <-- filter had no such error

    manager.errors.insert(.noRulesFound)

    verdict = manager.decideFlow(
      url: "https://api.gertrude.com/ios-filter-errors-v1/no-rules-found/vendor-id",
      bundleId: .gertrudeBundleIdShort
    )
    expect(verdict).toEqual(.allow) // <-- filter had error, so request allowed
    expect(manager.errors).toEqual([]) // <-- error should be cleared

    verdict = manager.decideFlow(
      url: "https://api.gertrude.com/ios-filter-errors-v1/rules-decode-failed/vendor-id",
      bundleId: .gertrudeBundleIdLong
    )

    expect(verdict).toEqual(.drop)

    manager.errors.insert(.rulesDecodeFailed)

    // assert that somebody can't manipulate our errors with a specially crafted url
    verdict = manager.decideFlow(
      url: "https://badguy.com/ios-filter-errors-v1/rules-decode-failed/exploit",
      bundleId: "com.not-matching.bundle.id"
    )
    expect(verdict).toEqual(.allow)
    expect(manager.errors).toEqual([.rulesDecodeFailed]) // <-- error should still be there

    verdict = manager.decideFlow(
      url: "https://api.gertrude.com/ios-filter-errors-v1/rules-decode-failed/vendor-id",
      bundleId: .gertrudeBundleIdLong
    )
    expect(verdict).toEqual(.allow)
    expect(manager.errors).toEqual([])
  }
}
