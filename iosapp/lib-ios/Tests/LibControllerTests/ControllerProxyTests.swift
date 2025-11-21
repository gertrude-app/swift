import ConcurrencyExtras
import Dependencies
import GertieIOS
import LibCore
import NetworkExtension
import Testing
import XExpect

@testable import LibController

struct ControllerProxyTest {
  let migrateCalled: LockIsolated<Bool> = .init(false)
  let loggedApiEvents: LockIsolated<[String]> = .init([])
  let notifyRulesChangedCount: LockIsolated<Int> = .init(0)
  let loadAccountConnectionCalled = LockIsolated<Int>(0)
  let osLogs: LockIsolated<[String]> = .init([])
  let refreshRulesCalls: LockIsolated<[ControllerProxy.RefreshReason]> = .init([])
  let loadDisabledBlockGroupsCalls: LockIsolated<Int> = .init(0)
  let loadProtectionModeCalls: LockIsolated<Int> = .init(0)
  let savedProtectionModes: LockIsolated<[ProtectionMode]> = .init([])
  let fetchBlockRulesCalls: LockIsolated<[Both<UUID, [BlockGroup]>]> = .init([])
  let connectedRulesCalls: LockIsolated<[UUID]> = .init([])
  let setAuthTokenCalls: LockIsolated<[UUID?]> = .init([])

  let _proxy: LockIsolated<ControllerProxy?> = .init(nil)

  var proxy: ControllerProxy {
    self._proxy.value!
  }

  func logged(_ message: String) -> Bool {
    self.osLogs.withValue { $0.contains(message) }
  }
}

@MainActor
func setup(
  performsMigration: Bool = false,
  accountConnected: Bool = false,
  disabledBlockGroups: [BlockGroup] = [],
  storedProtectionMode: ProtectionMode? = .normal([.targetContains(value: "stored.com")]),
  apiNormalRules: [BlockRule] = [.targetContains(value: "api.com")],
  apiConnectedRules: [BlockRule] = [.targetContains(value: "connected.com")],
  apiWebPolicy: WebContentFilterPolicy = .blockAll,
) async -> ControllerProxyTest {
  let test = ControllerProxyTest()

  withDependencies {
    $0.date = .constant(.reference)
    $0.osLog = .noop
    $0.osLog.log = { msg in test.osLogs.withValue { $0.append(msg) } }
    $0.osLog.debug = { msg in test.osLogs.withValue { $0.append(msg) } }
    $0.sharedStorage.migrateLegacyData = {
      test.migrateCalled.withValue { $0 = true }
      return performsMigration
    }
    $0.device.vendorId = { UUID(1) }
    $0.api.logEvent = { id, detail in
      await Task.megaYield() // ensure notify callback set in time for init migration
      test.loggedApiEvents.withValue { $0.append(id) }
    }
    $0.api.fetchBlockRules = { vendorId, disabledGroups in
      test.fetchBlockRulesCalls.withValue { $0.append(Both(vendorId, disabledGroups)) }
      return apiNormalRules
    }
    $0.api.connectedRules = { vendorId in
      test.connectedRulesCalls.withValue { $0.append(vendorId) }
      return .init(blockRules: apiConnectedRules, webPolicy: apiWebPolicy)
    }
    $0.api.setAuthToken = { token in
      test.setAuthTokenCalls.withValue { $0.append(token) }
    }
    $0.sharedStorage.loadDisabledBlockGroups = {
      test.loadDisabledBlockGroupsCalls.withValue { $0 += 1 }
      return disabledBlockGroups
    }
    $0.sharedStorage.loadProtectionMode = {
      test.loadProtectionModeCalls.withValue { $0 += 1 }
      return storedProtectionMode
    }
    $0.sharedStorage.loadAccountConnection = {
      test.loadAccountConnectionCalled.withValue { $0 += 1 }
      return !accountConnected ? nil : .init(
        childId: UUID(),
        token: UUID(2),
        deviceId: UUID(),
        childName: "Little Jimmy",
      )
    }
    $0.sharedStorage.saveProtectionMode = { mode in
      test.savedProtectionModes.withValue { $0.append(mode) }
    }
  } operation: {
    test._proxy.withValue { $0 = ControllerProxy() }
    test.proxy.notifyRulesChanged.withValue { $0 = {
      test.notifyRulesChangedCount.withValue { $0 += 1 }
    }}
    test.proxy.lastRefresh.withValue { $0 = .distantPast }
  }

  let task = test.proxy.migrateTask.withValue { $0! }
  await task.value

  return test
}

@Test func initPerformsMigration() async throws {
  let test = await setup(performsMigration: true)
  #expect(test.migrateCalled.value == true)
  #expect(test.loggedApiEvents.value == ["99bacaaa"])
  #expect(test.notifyRulesChangedCount.value == 1)
  #expect(test.logged("migration performed by controller"))
}

@Test func initSkipsMigrationWhenNotNeeded() async throws {
  let test = await setup(performsMigration: false)
  #expect(test.migrateCalled.value == true)
  #expect(test.loggedApiEvents.value == [])
  #expect(test.notifyRulesChangedCount.value == 0)
  #expect(false == test.logged("migration performed by controller"))
}

@Test func refreshRulesForStartupNotConnected() async throws {
  let test = await setup(accountConnected: false, disabledBlockGroups: [.ads])
  test.proxy.managedSettings.setValue(.init(named: .init("should clear")))

  // would debounce, but since =.startup, doesn't consult lastRefresh
  test.proxy.lastRefresh.withValue { $0 = .reference - .minutes(2) }

  await test.proxy.refreshRules(reason: .startup)

  #expect(test.loadAccountConnectionCalled.value == 1)
  #expect(test.proxy.lastRefresh.value == .reference - .minutes(2)) // not touched
  #expect(test.proxy.managedSettings.withValue { $0 == nil } == true) // cleared
  #expect(test.loadDisabledBlockGroupsCalls.value == 1)
  #expect(test.fetchBlockRulesCalls.value == [Both(UUID(1), [.ads])])
  #expect(test.savedProtectionModes.value == [.normal([.targetContains(value: "api.com")])])
  #expect(test.notifyRulesChangedCount.value == 1)
}

@Test func fauxHeartbeatRefreshNormalNotDebounced() async throws {
  let test = await setup(accountConnected: false)
  test.proxy.lastRefresh.withValue { $0 = .reference - .minutes(10) }

  let refreshed = await test.proxy.refreshRules(reason: .fauxHeartbeat)

  #expect(refreshed == true)
  #expect(test.proxy.lastRefresh.value == .reference) // updated
  #expect(test.fetchBlockRulesCalls.value == [Both(UUID(1), [])])
  #expect(test.savedProtectionModes.value == [.normal([.targetContains(value: "api.com")])])
  #expect(test.notifyRulesChangedCount.value == 1)
}

@Test func fauxHeartbeatRefreshNormalDebounced() async throws {
  let test = await setup(accountConnected: false)
  test.proxy.lastRefresh.withValue { $0 = .reference - .minutes(2) }

  let refreshed = await test.proxy.refreshRules(reason: .fauxHeartbeat)

  #expect(refreshed == false)
  #expect(test.proxy.lastRefresh.value == .reference - .minutes(2)) // unchanged
  #expect(test.savedProtectionModes.value == [])
  #expect(test.notifyRulesChangedCount.value == 0)
  #expect(test.logged("skipping rule refresh, debounce"))
}

@Test func doesNotSaveEmptyRulesFromApi() async throws {
  let test = await setup(apiNormalRules: [])

  let refreshed = await test.proxy.refreshRules(reason: .startup)

  #expect(refreshed == false)
  #expect(test.savedProtectionModes.value == [])
  #expect(test.notifyRulesChangedCount.value == 0)
  #expect(test.logged("unexpected empty rules from api"))
}

@Test func doesNotSaveOrNotifyWhenRulesUnchanged() async throws {
  let test = await setup(
    storedProtectionMode: .normal([.targetContains(value: "x.com")]),
    apiNormalRules: [.targetContains(value: "x.com")],
  )

  let refreshed = await test.proxy.refreshRules(reason: .startup)

  #expect(refreshed == false)
  #expect(test.savedProtectionModes.value == [])
  #expect(test.notifyRulesChangedCount.value == 0)
  #expect(test.logged("rules unchanged"))
  #expect(test.logged("saving changed rules") == false)
}

@Test func handleFilterFlowFauxHeartbeatAllowed() async throws {
  let test = await setup()

  let flow = FilterFlow(hostname: "example.com")
  let verdict = await test.proxy.handleFilterFlow(flow)

  #expect(verdict == .allow(withUpdateRules: true))
  #expect(test.proxy.lastRefresh.value == .reference) // updated
  #expect(test.savedProtectionModes.value == [.normal([.targetContains(value: "api.com")])])
  #expect(test.notifyRulesChangedCount.value == 1)
}

@Test func handleFilterFlowFauxHeartbeatBlocked() async throws {
  let test = await setup(apiNormalRules: [.targetContains(value: "stored.com")])

  let flow = FilterFlow(hostname: "stored.com")
  let verdict = await test.proxy.handleFilterFlow(flow)

  #expect(verdict == .drop(withUpdateRules: false))
  #expect(test.proxy.lastRefresh.value == .reference)
  #expect(test.savedProtectionModes.value == [])
  #expect(test.notifyRulesChangedCount.value == 0)
}

@Test func refreshConnectedRulesSetsAuthAndSaves() async throws {
  let test = await setup(accountConnected: true)

  let refreshed = await test.proxy.refreshRules(reason: .startup)

  #expect(refreshed == true)
  #expect(test.setAuthTokenCalls.value == [UUID(2)])
  #expect(test.connectedRulesCalls.value == [UUID(1)])
  #expect(test.savedProtectionModes.value == [
    .connected([.targetContains(value: "connected.com")], .blockAll),
  ])
  #expect(test.notifyRulesChangedCount.value == 1)
}

@Test func connectedRulesReturnsFalseWhenEmpty() async throws {
  let test = await setup(accountConnected: true, apiConnectedRules: [])

  let refreshed = await test.proxy.refreshRules(reason: .startup)

  #expect(refreshed == false)
  #expect(test.savedProtectionModes.value == [])
  #expect(test.notifyRulesChangedCount.value == 0)
  #expect(test.logged("unexpected empty rules from api (connected)"))
}

@Test func connectedRulesReturnsFalseWhenUnchanged() async throws {
  let rules: [BlockRule] = [.targetContains(value: "x.com")]
  let policy: WebContentFilterPolicy = .blockAdult
  let test = await setup(
    accountConnected: true,
    storedProtectionMode: .connected(rules, policy),
    apiConnectedRules: rules,
    apiWebPolicy: policy,
  )

  let refreshed = await test.proxy.refreshRules(reason: .startup)

  #expect(refreshed == false)
  #expect(test.savedProtectionModes.value == [])
  #expect(test.notifyRulesChangedCount.value == 0)
  #expect(test.logged("rules unchanged (connected)"))
}

@Test func connectedRulesUpdatesManagedSettingsStore() async throws {
  let test = await setup(
    accountConnected: true,
    apiWebPolicy: .blockAdultAnd(["bad.com"]),
  )

  test.proxy.managedSettings.withValue { store in
    #expect(store?.gertiePolicy != .blockAdultAnd(["bad.com"]))
  }

  await test.proxy.refreshRules(reason: .startup)

  test.proxy.managedSettings.withValue { store in
    #expect(store != nil)
    #expect(store?.gertiePolicy == .blockAdultAnd(["bad.com"]))
  }
}

public struct Both<A: Equatable & Sendable, B: Equatable & Sendable>: Equatable, Sendable {
  public var a: A
  public var b: B
  public init(_ a: A, _ b: B) {
    self.a = a
    self.b = b
  }
}

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}
