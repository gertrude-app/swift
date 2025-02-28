import ConcurrencyExtras
import Dependencies
import LibCore
import XCTest
import XExpect

@testable import LibFilter

final class FilterProxyTests: XCTestCase {
  func testLockdownModeBlocking() async throws {
    let cases: [(host: String?, url: String?, bundleId: String?, expect: FilterProxy.FlowVerdict)] =
      [
        ("api.gertrude.app", nil, nil, .allow),
        (nil, "api.gertrude.app", nil, .allow),
        (nil, "https://api.gertrude.app", nil, .allow),
        (nil, "anysite.com", String.gertrudeBundleIdLong, .allow),
        (nil, "anysite.com", String.gertrudeBundleIdShort, .allow),
        (nil, "anysite.com", ".\(String.gertrudeBundleIdLong)", .allow),
        (nil, "anysite.com", ".\(String.gertrudeBundleIdShort)", .allow),
        ("anothersite.com", nil, String.gertrudeBundleIdLong, .allow),
        ("anothersite.com", nil, String.gertrudeBundleIdShort, .allow),
        (nil, "api.gertrude.app/pairql/foo/bar", nil, .allow),
        ("gertrude.app", nil, nil, .allow),
        (nil, "gertrude.app/docs", nil, .allow),
        ("api.gertrude.app", nil, "com.acme", .allow),
        ("gertrude.app", nil, "com.acme", .allow),
        (nil, "gertrude.app/foo/bar", "com.acme", .allow),
        (nil, "sneaky.com/gertrude.app/foo/bar", "com.acme", .drop),
        (nil, "bad.com/gertrude.app", nil, .drop),
        ("api.gertrude.app", nil, "com.acme.com", .allow),
        (nil, "anysite.com", "12345.com.acme", .drop),
        ("anothersite.com", nil, "com.acme", .drop),
        (nil, nil, nil, .drop),
        ("safesite.com", nil, nil, .drop),
        (nil, "safesite.com", nil, .drop),
      ]

    let proxy = withDependencies {
      $0.osLog.log = { _ in }
      $0.storage.loadData = { @Sendable _ in nil }
    } operation: {
      FilterProxy(protectionMode: .emergencyLockdown)
    }
    for (host, url, bundleId, expected) in cases {
      expect(proxy.decideFlow(hostname: host, url: url, bundleId: bundleId, flowType: nil))
        .toEqual(expected)
      expect(proxy.decideFlow(hostname: host, url: url, bundleId: bundleId, flowType: .browser))
        .toEqual(expected)
      expect(proxy.decideFlow(hostname: host, url: url, bundleId: bundleId, flowType: .socket))
        .toEqual(expected)
    }
  }

  func testReadsRulesInHeartbeat() async throws {
    let logs = LockIsolated<[String]>([])
    let rules = LockIsolated<ProtectionMode>(.normal([.urlContains("foo")]))
    let clock = TestClock()

    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.suspendingClock = clock
      $0.storage.loadData = { @Sendable _ in
        try! JSONEncoder().encode(rules.value)
      }
    } operation: {
      FilterProxy(protectionMode: .emergencyLockdown)
    }

    // initializer loads protection rules from storage
    expect(proxy.protectionMode).toEqual(.normal([.urlContains("foo")]))
    expect(logs.value).toEqual(["read 1 (normal) rules"])

    proxy.startHeartbeat(interval: .seconds(60))
    await clock.advance(by: .seconds(59))

    // no heartbeat yet
    expect(logs.value).toEqual(["read 1 (normal) rules"])
    rules.setValue(.normal([.urlContains("bar"), .urlContains("baz")]))

    // heartbeat should happen here
    await clock.advance(by: .seconds(1))
    expect(logs.value).toEqual(["read 1 (normal) rules", "read 2 (normal) rules"])
    expect(proxy.protectionMode).toEqual(.normal([.urlContains("bar"), .urlContains("baz")]))
  }

  func testReadsRulesOnStart() {
    let logs = LockIsolated<[String]>([])
    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.storage.loadData = { @Sendable key in
        expect(key).toEqual(.protectionModeStorageKey)
        return try! JSONEncoder().encode(ProtectionMode.normal([.urlContains("lol")]))
      }
    } operation: {
      FilterProxy(protectionMode: .normal([]))
    }

    expect(proxy.protectionMode).toEqual(.normal([.urlContains("lol")]))
    expect(logs.value).toEqual(["read 1 (normal) rules"])
  }

  func testHandleRulesChangesCausesReadRules() {
    let logs = LockIsolated<[String]>([])
    let rules = LockIsolated<ProtectionMode>(.normal([.urlContains("foo")]))

    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.storage.loadData = { @Sendable _ in
        try! JSONEncoder().encode(rules.value)
      }
    } operation: {
      FilterProxy(protectionMode: .normal([]))
    }

    // init
    expect(proxy.protectionMode).toEqual(.normal([.urlContains("foo")]))
    expect(logs.value).toEqual(["read 1 (normal) rules"])

    rules.setValue(.normal([.urlContains("bar"), .urlContains("baz")]))
    proxy.handleRulesChanged()

    expect(logs.value).toEqual(["read 1 (normal) rules", "read 2 (normal) rules"])
    expect(proxy.protectionMode).toEqual(.normal([.urlContains("bar"), .urlContains("baz")]))
  }

  func testReadRulesNilLogsErrAndKeepsOldRules() {
    let logs = LockIsolated<[String]>([])

    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.storage.loadData = { @Sendable _ in nil }
    } operation: {
      FilterProxy(protectionMode: .normal([.urlContains("old")]))
    }

    expect(proxy.protectionMode).toEqual(.normal([.urlContains("old")]))
    expect(logs.value).toEqual(["no rules found"])

    proxy.receiveHeartbeat()

    expect(proxy.protectionMode).toEqual(.normal([.urlContains("old")]))
    expect(logs.value).toEqual(["no rules found", "no rules found"])
  }

  func testReadRulesDecodeErrorLogsErrAndKeepsOldRules() {
    struct TestError: Error {}
    let logs = LockIsolated<[String]>([])

    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.storage.loadData = { @Sendable _ in
        String("nope").data(using: .utf8)! // <-- error
      }
    } operation: {
      FilterProxy(protectionMode: .normal([.urlContains("old")]))
    }

    expect(logs.value.count).toEqual(1)
    expect(logs.value[0]).toContain("error decoding rules:")

    // we keep the rules
    expect(proxy.protectionMode).toEqual(.normal([.urlContains("old")]))
  }
}
