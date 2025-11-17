import Dependencies
import Foundation
import LibCore
import Testing
import XExpect

@testable import LibFilter

@Test func lockdownModeBlocking() throws {
  let cases: [(host: String?, url: String?, bundleId: String?, expect: FlowVerdict)] =
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

  let (_, proxy) = setup(now: Date(timeIntervalSince1970: 400))
  for (host, url, bundleId, expected) in cases {
    expect(proxy.decideNewFlow(.init(
      hostname: host,
      url: url,
      bundleId: bundleId,
      flowType: nil,
    ))).toEqual(expected)
    expect(proxy.decideNewFlow(.init(
      hostname: host,
      url: url,
      bundleId: bundleId,
      flowType: .browser,
    ))).toEqual(expected)
    expect(proxy.decideNewFlow(.init(
      hostname: host,
      url: url,
      bundleId: bundleId,
      flowType: .socket,
    ))).toEqual(expected)
  }
}

@Test func lockDownRecoveryWindow() {
  var components = DateComponents()
  components.hour = 19
  components.minute = 3
  let window = Calendar.current.date(from: components)!
  let (_, proxy) = setup(now: window)
  expect(proxy.decideNewFlow(.init(
    hostname: "any.com",
    url: "any.com",
    bundleId: "com.x",
    flowType: nil,
  )))
  .toEqual(.allow)
}

struct FilterTestCase {
  let osLogs: LockIsolated<[String]> = .init([])
  let loadProtectionModeCalls: LockIsolated<Int> = .init(0)

  func logged(_ message: String) -> Bool {
    self.osLogs.withValue { $0.contains(message) }
  }
}

func setup(
  now: Date = .reference + .hours(5),
  initialProtectionMode: ProtectionMode = .emergencyLockdown,
  storedProtectionMode: ProtectionMode? = .normal([.urlContains(value: "bad")]),
) -> (FilterTestCase, FilterProxy) {
  let test = FilterTestCase()
  let proxy = withDependencies {
    $0.date = .constant(now)
    $0.osLog = .noop
    $0.osLog.log = { msg in test.osLogs.withValue { $0.append(msg) } }
    $0.calendar = Calendar(identifier: .gregorian)
    $0.sharedStorageReader.loadProtectionMode = { @Sendable in
      test.loadProtectionModeCalls.withValue { $0 += 1 }
      return storedProtectionMode
    }
  } operation: {
    FilterProxy(protectionMode: initialProtectionMode)
  }
  test.osLogs.withValue { $0.removeAll() } // clear init logs
  return (test, proxy)
}

@Test func startFilterCausesReadRules() {
  var (test, proxy) = setup()
  #expect(test.loadProtectionModeCalls.value == 0)

  proxy.startFilter()

  #expect(test.loadProtectionModeCalls.value == 1)
  #expect(test.logged("Starting filter"))
  #expect(test.logged("read 1 (normal) rules"))
}

@Test func respondToReadRulesSentinal() {
  var (test, proxy) = setup()
  proxy.count = 11

  let verdict = proxy.decideFilterFlow(.init(hostname: MagicStrings.readRulesSentinalHostname))

  #expect(verdict == .drop)
  #expect(test.loadProtectionModeCalls.value == 1)
  #expect(test.osLogs.value == ["read 1 (normal) rules"])
  #expect(proxy.count == 12)
}

@Test func respondToRefreshRulesSentinal() {
  var (test, proxy) = setup()
  proxy.count = 11

  let verdict = proxy.decideFilterFlow(.init(hostname: MagicStrings.refreshRulesSentinalHostname))

  #expect(verdict == .needRules) // tells the controller layer we need rules
  #expect(test.loadProtectionModeCalls.value == 0)
  #expect(test.osLogs.value == ["refresh rules requested from app"])
  #expect(proxy.count == 12)
}

@Test func requestsUpdatePeriodicallyInNormalMode() {
  var (test, proxy) = setup(initialProtectionMode: .normal([.targetContains(value: "bad.com")]))
  proxy.count = FilterProxy.FREQ_SLOW * 3 - 2

  // haven't hit faux-heartbeat yet, won't read any rules
  let verdict1 = proxy.decideFilterFlow(.init(hostname: "ok.com"))

  #expect(verdict1 == .allow)
  #expect(test.loadProtectionModeCalls.value == 0)

  // now we hit the faux-heartbeat
  let verdict2 = proxy.decideFilterFlow(.init(hostname: "bad.com"))

  #expect(verdict2 == .needRules)
  #expect(test.loadProtectionModeCalls.value == 0)
  #expect(test.logged("request update, count: \(FilterProxy.FREQ_SLOW * 3)"))
}

@Test func requestsUpdatePeriodicallyInConnectedMode() {
  var (test, proxy) = setup(initialProtectionMode: .connected(
    [.targetContains(value: "bad.com")],
    .blockAll,
  ))
  proxy.count = FilterProxy.FREQ_NORMAL * 3 - 2

  // haven't hit faux-heartbeat yet, won't read any rules
  let verdict1 = proxy.decideFilterFlow(.init(hostname: "ok.com"))

  #expect(verdict1 == .allow)
  #expect(test.loadProtectionModeCalls.value == 0)

  // now we hit the faux-heartbeat
  let verdict2 = proxy.decideFilterFlow(.init(hostname: "bad.com"))

  #expect(verdict2 == .needRules)
  #expect(test.loadProtectionModeCalls.value == 0)
  #expect(test.logged("request update, count: \(FilterProxy.FREQ_NORMAL * 3)"))
}

@Test func requestsUpdatePeriodicallyInOnboardingMode() {
  var (test, proxy) = setup(initialProtectionMode: .onboarding([.targetContains(value: "bad.com")]))
  proxy.count = FilterProxy.FREQ_FAST * 3 - 2

  // haven't hit faux-heartbeat yet, won't read any rules
  let verdict1 = proxy.decideFilterFlow(.init(hostname: "ok.com"))

  #expect(verdict1 == .allow)
  #expect(test.loadProtectionModeCalls.value == 0)

  // now we hit the faux-heartbeat
  let verdict2 = proxy.decideFilterFlow(.init(hostname: "bad.com"))

  #expect(verdict2 == .needRules)
  #expect(test.loadProtectionModeCalls.value == 0)
  #expect(test.logged("request update, count: \(FilterProxy.FREQ_FAST * 3)"))
}

@Test func requestsUpdatePeriodicallyInEmergencyLockdownMode() {
  var (test, proxy) = setup(initialProtectionMode: .emergencyLockdown, storedProtectionMode: nil)
  proxy.count = FilterProxy.FREQ_FAST * 3 - 2

  // haven't hit faux-heartbeat yet, will use lockdown rules
  let verdict1 = proxy.decideFilterFlow(.init(hostname: "ok.com"))

  #expect(verdict1 == .drop)
  #expect(test.loadProtectionModeCalls.value == 1)

  // now we hit the faux - heartbeat, rules loaded again
  let verdict2 = proxy.decideFilterFlow(.init(hostname: "bad.com"))

  #expect(verdict2 == .needRules)
  #expect(test.loadProtectionModeCalls.value == 2)
  #expect(test.logged("request update, count: \(FilterProxy.FREQ_FAST * 3)"))
}

@Test func reReadsRulesPeriodicallyAsVerySlowFallback() {
  var (test, proxy) = setup(initialProtectionMode: .normal([.targetContains(value: "bad.com")]))
  proxy.count = FilterProxy.FREQ_VERY_SLOW * 3 - 2

  // haven't hit FREQ_VERY_SLOW yet, won't read any rules
  let verdict1 = proxy.decideFilterFlow(.init(hostname: "ok.com"))

  #expect(verdict1 == .allow)
  #expect(test.loadProtectionModeCalls.value == 0)

  // now we hit the FREQ_VERY_SLOW fallback, rules ARE loaded
  let verdict2 = proxy.decideFilterFlow(.init(hostname: "bad.com"))

  #expect(verdict2 == .needRules)
  #expect(test.loadProtectionModeCalls.value == 1)
  #expect(test.logged("re-read rules fallback, count: \(FilterProxy.FREQ_VERY_SLOW * 3)"))
}

@Test func handleRulesChangedCausesReadRules() {
  let test = FilterTestCase()
  let reads: LockIsolated<[ProtectionMode?]> = .init([
    .normal([.targetContains(value: "one.com")]),
    .normal([.targetContains(value: "two.com")]),
    nil,
  ])
  var proxy = withDependencies {
    $0.osLog = .noop
    $0.osLog.log = { msg in test.osLogs.withValue { $0.append(msg) } }
    $0.sharedStorageReader.loadProtectionMode = { @Sendable in
      test.loadProtectionModeCalls.withValue { $0 += 1 }
      return reads.withValue { $0.isEmpty ? nil : $0.removeFirst() }
    }
  } operation: {
    FilterProxy(protectionMode: .emergencyLockdown)
  }

  #expect(proxy.protectionMode == .emergencyLockdown)
  let verdict1 = proxy.decideFilterFlow(.init(hostname: "one.com"))
  #expect(proxy.protectionMode == .normal([.targetContains(value: "one.com")]))
  #expect(verdict1 == .drop)
  #expect(test.loadProtectionModeCalls.value == 1)

  proxy.handleRulesChanged()

  #expect(proxy.protectionMode == .normal([.targetContains(value: "two.com")]))
  #expect(test.loadProtectionModeCalls.value == 2)

  let verdict2 = proxy.decideFilterFlow(.init(hostname: "one.com"))
  #expect(verdict2 == .allow)

  // now if we read a nil, we should keep the old rules
  proxy.handleRulesChanged()

  #expect(test.logged("no rules found"))
  #expect(test.loadProtectionModeCalls.value == 3)
  #expect(proxy.protectionMode == .normal([.targetContains(value: "two.com")]))
  #expect(reads.value.isEmpty)
}

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}
