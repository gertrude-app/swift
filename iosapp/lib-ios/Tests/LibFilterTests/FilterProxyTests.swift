import ConcurrencyExtras
import Dependencies
import XCTest
import XExpect

@testable import LibFilter

final class FilterProxyTests: XCTestCase {
  func testReadsRulesInHeartbeat() async throws {
    let logs = LockIsolated<[String]>([])
    let rules = LockIsolated<[BlockRule]>([.urlContains("foo")])
    let clock = TestClock()

    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.suspendingClock = clock
      $0.storage.loadData = { @Sendable _ in
        try! JSONEncoder().encode(rules.value)
      }
    } operation: {
      FilterProxy(rules: [])
    }

    expect(proxy.rules).toEqual([.urlContains("foo")])
    expect(logs.value).toEqual(["read 1 rules"])

    proxy.startHeartbeat(interval: .seconds(60))
    await clock.advance(by: .seconds(59))

    // no heartbeat yet
    expect(logs.value).toEqual(["read 1 rules"])
    rules.setValue([.urlContains("bar"), .urlContains("baz")])

    // heartbeat should happen here
    await clock.advance(by: .seconds(1))
    expect(logs.value).toEqual(["read 1 rules", "read 2 rules"])
    expect(proxy.rules).toEqual([.urlContains("bar"), .urlContains("baz")])
  }

  func testReadsRulesOnStart() {
    let logs = LockIsolated<[String]>([])
    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.storage.loadData = { @Sendable key in
        expect(key).toEqual(.blockRulesStorageKey)
        return try! JSONEncoder().encode([BlockRule.urlContains("lol")])
      }
    } operation: {
      FilterProxy(rules: [])
    }

    expect(proxy.rules).toEqual([.urlContains("lol")])
    expect(logs.value).toEqual(["read 1 rules"])
  }

  func testHandleRulesChangesCausesReadRules() {
    let logs = LockIsolated<[String]>([])
    let rules = LockIsolated<[BlockRule]>([.urlContains("foo")])

    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.storage.loadData = { @Sendable _ in
        try! JSONEncoder().encode(rules.value)
      }
    } operation: {
      FilterProxy(rules: [])
    }

    // init
    expect(proxy.rules).toEqual([.urlContains("foo")])
    expect(logs.value).toEqual(["read 1 rules"])

    rules.setValue([.urlContains("bar"), .urlContains("baz")])
    proxy.handleRulesChanged()

    expect(logs.value).toEqual(["read 1 rules", "read 2 rules"])
    expect(proxy.rules).toEqual([.urlContains("bar"), .urlContains("baz")])
  }

  func testReadRulesNilLogsErrAndKeepsOldRules() {
    let logs = LockIsolated<[String]>([])

    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.storage.loadData = { @Sendable _ in nil }
    } operation: {
      FilterProxy(rules: [.urlContains("old")])
    }

    expect(proxy.rules).toEqual([.urlContains("old")])
    expect(logs.value).toEqual(["no rules found"])

    proxy.receiveHeartbeat()

    expect(proxy.rules).toEqual([.urlContains("old")])
    expect(logs.value).toEqual(["no rules found", "no rules found"])
  }

  func testReadRulesDecodeErrorLogsErrAndKeepsOldRules() {
    struct TestError: Error {}
    let logs = LockIsolated<[String]>([])

    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.storage.loadData = { @Sendable _ in
        String("nope").data(using: .utf8)!
      }
    } operation: {
      FilterProxy(rules: [.urlContains("old")])
    }

    expect(logs.value.count).toEqual(1)
    expect(logs.value[0]).toContain("error decoding rules:")

    // we keep the rules
    expect(proxy.rules).toEqual([.urlContains("old")])
  }
}
