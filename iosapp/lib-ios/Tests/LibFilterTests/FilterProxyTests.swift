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
        ("safesite.com", nil, nil, .drop),
        (nil, "safesite.com", nil, .drop),
        // allowances for screen time auth
        ("apple.com", nil, "com.acme", .allow),
        ("configuration.icloud.com", nil, "com.acme", .allow),
        ("configuration.icloud.net", nil, "com.acme", .allow),
        ("bag.itunes.apple.com", nil, "com.acme", .allow),
        ("fbs.smoot.apple.com", nil, "com.acme", .allow),
        ("smp-device-content.apple.com", nil, "com.acme", .allow),
        ("badbad.com", nil, "com.apple.mDNSResponder", .allow),
        ("badbad.com", nil, "com.apple.Preferences", .allow),
        (nil, nil, "com.anybody", .allow),
      ]

    let proxy = withDependencies {
      $0.osLog.log = { _ in }
      $0.storage.loadData = { @Sendable _ in nil }
      $0.suspendingClock = TestClock()
      $0.calendar = Calendar(identifier: .gregorian)
      $0.date = .constant(Date(timeIntervalSince1970: 400))
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

  func testLockDownRecoveryWindow() {
    var components = DateComponents()
    components.hour = 19
    components.minute = 3
    let now = Calendar.current.date(from: components)!
    let proxy = withDependencies {
      $0.osLog.log = { _ in }
      $0.storage.loadData = { @Sendable _ in nil }
      $0.suspendingClock = TestClock()
      $0.calendar = Calendar(identifier: .gregorian)
      $0.date = .constant(now)
    } operation: {
      FilterProxy(protectionMode: .emergencyLockdown)
    }
    expect(proxy.decideFlow(hostname: "any.com", url: "any.com", bundleId: "com.x", flowType: nil))
      .toEqual(.allow)
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
      FilterProxy(
        protectionMode: .emergencyLockdown,
        normalHeartbeatInterval: .seconds(60)
      )
    }

    // initializer loads protection rules from storage
    expect(proxy.getProtectionMode).toEqual(.normal([.urlContains("foo")]))
    expect(logs.value).toEqual(["read 1 (normal) rules"])

    await clock.advance(by: .seconds(59))

    // no heartbeat yet
    expect(logs.value).toEqual(["read 1 (normal) rules"])
    rules.setValue(.normal([.urlContains("bar"), .urlContains("baz")]))

    // heartbeat should happen here
    await clock.advance(by: .seconds(1))
    expect(logs.value).toEqual(["read 1 (normal) rules", "read 2 (normal) rules"])
    expect(proxy.getProtectionMode).toEqual(.normal([.urlContains("bar"), .urlContains("baz")]))
  }

  // simulate user defaults not being available on first boot, before unlock
  // we need to keep checking quickly until they are available to not be in lockdown long
  // @see https://christianselig.com/2024/10/beware-userdefaults/
  func testNoDataFoundCausesFasterRecheckUntilFound() async throws {
    let logs = LockIsolated<[String]>([])
    let userDefaultsReady = LockIsolated(false)
    let clock = TestClock()
    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.suspendingClock = clock
      $0.storage.loadData = { @Sendable _ in
        if !userDefaultsReady.value {
          return nil
        } else {
          return try! JSONEncoder().encode(ProtectionMode.normal([.urlContains("foo")]))
        }
      }
    } operation: {
      FilterProxy(
        protectionMode: .emergencyLockdown,
        normalHeartbeatInterval: .minutes(5)
      )
    }

    // initializer tries to load, but finds no rules, goes into lockdown
    expect(proxy.getProtectionMode).toEqual(.emergencyLockdown)
    expect(logs.value).toEqual(["no rules found"])

    await clock.advance(by: .seconds(9))
    expect(logs.value).toEqual(["no rules found"])

    // because we have no rules, we're checking every ten seconds
    await clock.advance(by: .seconds(1))
    expect(logs.value).toEqual(["no rules found", "no rules found"])
    await clock.advance(by: .seconds(10))
    expect(logs.value).toEqual(["no rules found", "no rules found", "no rules found"])

    // simulate user defaults ready
    userDefaultsReady.setValue(true)
    await clock.advance(by: .seconds(9))
    expect(logs.value.count).toEqual(3)
    await clock.advance(by: .seconds(1))
    expect(logs.value).toEqual([
      "no rules found",
      "no rules found",
      "no rules found",
      "read 1 (normal) rules",
    ])
    expect(proxy.getProtectionMode).toEqual(.normal([.urlContains("foo")]))

    // now, we are not checking so often
    await clock.advance(by: .seconds(10))
    expect(logs.value.count).toEqual(4)

    await clock.advance(by: .minutes(5))
    expect(logs.value.count).toEqual(5)
  }

  func testReadsRulesOnStart() {
    let logs = LockIsolated<[String]>([])
    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.suspendingClock = TestClock()
      $0.storage.loadData = { @Sendable key in
        expect(key).toEqual(.protectionModeStorageKey)
        return try! JSONEncoder().encode(ProtectionMode.normal([.urlContains("lol")]))
      }
    } operation: {
      FilterProxy(protectionMode: .normal([]))
    }

    expect(proxy.getProtectionMode).toEqual(.normal([.urlContains("lol")]))
    expect(logs.value).toEqual(["read 1 (normal) rules"])
  }

  func testHandleRulesChangesCausesReadRules() {
    let logs = LockIsolated<[String]>([])
    let rules = LockIsolated<ProtectionMode>(.normal([.urlContains("foo")]))

    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.suspendingClock = TestClock()
      $0.storage.loadData = { @Sendable _ in
        try! JSONEncoder().encode(rules.value)
      }
    } operation: {
      FilterProxy(protectionMode: .normal([]))
    }

    // init
    expect(proxy.getProtectionMode).toEqual(.normal([.urlContains("foo")]))
    expect(logs.value).toEqual(["read 1 (normal) rules"])

    rules.setValue(.normal([.urlContains("bar"), .urlContains("baz")]))
    proxy.handleRulesChanged()

    expect(logs.value).toEqual(["read 1 (normal) rules", "read 2 (normal) rules"])
    expect(proxy.getProtectionMode).toEqual(.normal([.urlContains("bar"), .urlContains("baz")]))
  }

  func testReadRulesNilLogsErrAndKeepsOldRules() {
    let logs = LockIsolated<[String]>([])

    let proxy = withDependencies {
      $0.osLog.log = { msg in logs.withValue { $0.append(msg) } }
      $0.storage.loadData = { @Sendable _ in nil }
      $0.suspendingClock = TestClock()
    } operation: {
      FilterProxy(protectionMode: .normal([.urlContains("old")]))
    }

    expect(proxy.getProtectionMode).toEqual(.normal([.urlContains("old")]))
    expect(logs.value).toEqual(["no rules found"])

    proxy.receiveHeartbeat()

    expect(proxy.getProtectionMode).toEqual(.normal([.urlContains("old")]))
    expect(logs.value).toEqual(["no rules found", "no rules found"])
  }

  func testReadRulesDecodeErrorLogsErrAndKeepsOldRules() {
    struct TestError: Error {}
    let logs = LockIsolated<[String]>([])

    let proxy = withDependencies {
      $0.suspendingClock = TestClock()
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
    expect(proxy.getProtectionMode).toEqual(.normal([.urlContains("old")]))
  }
}

extension FilterProxy {
  var getProtectionMode: ProtectionMode {
    protectionMode.withLock { $0 }
  }
}
