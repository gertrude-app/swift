import Combine
import ComposableArchitecture
import GertieIOS
import IOSRoute
import LibCore
import Testing

@testable import LibApp
@testable import LibClients

@MainActor
@Test func clearCacheButtonFlow() async throws {
  nonisolated(unsafe) let cacheClearSubject = PassthroughSubject<
    DeviceClient.ClearCacheUpdate,
    Never
  >()

  let store = TestStore(initialState: InfoFeature.State()) {
    InfoFeature()
  } withDependencies: {
    $0.mainQueue = .immediate
    $0.date = .constant(.reference)
    $0.api.logEvent = { @Sendable _, _ in }
    $0.device.batteryLevel = { .level(0.15) }
    $0.device.availableDiskSpaceInBytes = { 1024 * 1024 * 50 }
    $0.device.clearCache = { _ in
      cacheClearSubject.eraseToAnyPublisher()
    }
  }

  await store.send(.clearCacheTapped) {
    $0.subScreen = .explainClearCache1
  }

  await store.send(.explainClearCacheNextTapped) {
    $0.subScreen = .explainClearCache2
  }

  await store.send(.explainClearCacheNextTapped) {
    $0.subScreen = .clearingCache
    $0.clearCache = .init(context: .info)
  }

  await store.send(.clearCache(.onAppear))

  await store.receive(.clearCache(.receivedDeviceInfo(
    batteryLevel: .level(0.15),
    availableSpace: 1024 * 1024 * 50,
  ))) {
    $0.clearCache?.batteryLevel = .level(0.15)
    $0.clearCache?.screen = .batteryWarning
    $0.clearCache?.availableDiskSpaceInBytes = 1024 * 1024 * 50
  }

  await store.send(.clearCache(.batteryWarningContinueTapped)) {
    $0.clearCache?.screen = .clearing
    $0.clearCache?.startClearCache = .reference
  }

  cacheClearSubject.send(.bytesCleared(1024 * 512))
  await store.receive(.clearCache(.receivedClearCacheUpdate(.bytesCleared(1024 * 512)))) {
    $0.clearCache?.bytesCleared = 1024 * 512
  }

  cacheClearSubject.send(.finished)
  await store.receive(.clearCache(.receivedClearCacheUpdate(.finished))) {
    $0.clearCache?.screen = .cleared
  }

  await store.send(.clearCache(.completeBtnTapped)) {
    $0.clearCache = nil
    $0.subScreen = .main
  }
}

@MainActor
@Test func unconnectedRecoveryWithGoodData() async throws {
  let apiLoggedEvents = LockIsolated<[Both<String, String?>]>([])
  let filterNotifications = LockIsolated<[FilterClient.Notification]>([])
  let recoveryDirectiveInvocations = LockIsolated(0)
  let dismissInvocations = LockIsolated(0)
  let vendorId = UUID()

  let store = TestStore(initialState: InfoFeature.State(
    connection: nil,
    vendorId: vendorId,
  )) {
    InfoFeature()
  } withDependencies: {
    $0.api.logEvent = { @Sendable id, detail in
      apiLoggedEvents.withValue { $0.append(Both(id, detail)) }
    }
    $0.sharedStorage.loadDisabledBlockGroups = { @Sendable in
      [.whatsAppFeatures]
    }
    $0.sharedStorage.saveDisabledBlockGroups = { @Sendable _ in
      fatalError("saveDisabledBlockGroups should not be called")
    }
    $0.sharedStorage.loadProtectionMode = { @Sendable in
      .normal([.urlContains(value: "existing-rule")])
    }
    $0.sharedStorage.saveProtectionMode = { @Sendable _ in
      fatalError("saveProtectionMode should not be called")
    }
    $0.filter.send = { @Sendable notification in
      filterNotifications.withValue { $0.append(notification) }
    }
    $0.api.recoveryDirective = { @Sendable in
      recoveryDirectiveInvocations.withValue { $0 += 1 }
      return nil
    }
    $0.dismiss = .init {
      dismissInvocations.withValue { $0 += 1 }
    }
  }

  await store.shake(times: 5)
  await store.send(.receivedShake) { $0.timesShaken = 0 }

  #expect(apiLoggedEvents.value == [Both("a8998540", "entering recovery mode")])
  #expect(filterNotifications.value == [.rulesChanged])
  #expect(recoveryDirectiveInvocations.value == 1)
  #expect(dismissInvocations.value == 1)
}

@MainActor
@Test func unconnectedRecoveryWithMissingDisabledBlockGroups() async throws {
  let recoveryDirectiveInvocations = LockIsolated(0)
  let apiLoggedEvents = LockIsolated<[Both<String, String?>]>([])
  let savedDisabledBlockGroups = LockIsolated<[[BlockGroup]]>([])
  let filterNotifications = LockIsolated<[FilterClient.Notification]>([])
  let dismissInvocations = LockIsolated(0)

  let store = TestStore(initialState: InfoFeature.State(connection: nil)) {
    InfoFeature()
  } withDependencies: {
    $0.api.logEvent = { @Sendable id, detail in
      apiLoggedEvents.withValue { $0.append(Both(id, detail)) }
    }
    $0.sharedStorage.loadDisabledBlockGroups = { @Sendable in
      nil // <-- missing disabled block groups triggers save
    }
    $0.sharedStorage.saveDisabledBlockGroups = { @Sendable groups in
      savedDisabledBlockGroups.withValue { $0.append(groups) }
    }
    $0.sharedStorage.loadProtectionMode = { @Sendable in
      .normal([.urlContains(value: "existing-rule")])
    }
    $0.sharedStorage.saveProtectionMode = { @Sendable _ in
      fatalError("saveProtectionMode should not be called")
    }
    $0.filter.send = { @Sendable notification in
      filterNotifications.withValue { $0.append(notification) }
    }
    $0.api.recoveryDirective = { @Sendable in
      recoveryDirectiveInvocations.withValue { $0 += 1 }
      return nil
    }
    $0.dismiss = .init {
      dismissInvocations.withValue { $0 += 1 }
    }
  }

  await store.shake(times: 5)
  await store.send(.receivedShake) { $0.timesShaken = 0 }

  #expect(apiLoggedEvents.value == [Both("a8998540", "entering recovery mode")])
  #expect(savedDisabledBlockGroups.value == [[]]) // <-- saved empty disabled block groups
  #expect(filterNotifications.value == [.rulesChanged])
  #expect(recoveryDirectiveInvocations.value == 1)
  #expect(dismissInvocations.value == 1)
}

@MainActor
@Test func unconnectedRecoveryWithMissingRulesSuccessfulFetch() async throws {
  let apiLoggedEvents = LockIsolated<[Both<String, String?>]>([])
  let savedProtectionModes = LockIsolated<[ProtectionMode]>([])
  let fetchDefaultRulesInvocations = LockIsolated(0)
  let filterNotifications = LockIsolated<[FilterClient.Notification]>([])
  let recoveryDirectiveInvocations = LockIsolated(0)
  let dismissInvocations = LockIsolated(0)

  let store = TestStore(initialState: InfoFeature.State(connection: nil)) {
    InfoFeature()
  } withDependencies: {
    $0.device.vendorId = { UUID(1) }
    $0.api.logEvent = { @Sendable id, detail in
      apiLoggedEvents.withValue { $0.append(Both(id, detail)) }
    }
    $0.sharedStorage.loadDisabledBlockGroups = { @Sendable in [] }
    $0.sharedStorage.saveDisabledBlockGroups = { @Sendable _ in
      fatalError("saveDisabledBlockGroups should not be called")
    }
    $0.sharedStorage.loadProtectionMode = { @Sendable in
      nil // <-- missing rules trigger fetch
    }
    $0.sharedStorage.saveProtectionMode = { @Sendable mode in
      savedProtectionModes.withValue { $0.append(mode) }
    }
    $0.api.fetchDefaultBlockRules = { @Sendable vid in
      #expect(vid == UUID(1))
      fetchDefaultRulesInvocations.withValue { $0 += 1 }
      return [.urlContains(value: "default-from-api")]
    }
    $0.filter.send = { @Sendable notification in
      filterNotifications.withValue { $0.append(notification) }
    }
    $0.api.recoveryDirective = { @Sendable in
      recoveryDirectiveInvocations.withValue { $0 += 1 }
      return nil
    }
    $0.dismiss = .init {
      dismissInvocations.withValue { $0 += 1 }
    }
  }

  await store.shake(times: 5)
  await store.send(.receivedShake) { $0.timesShaken = 0 }

  #expect(apiLoggedEvents.value == [
    Both("a8998540", "entering recovery mode"),
    Both("bcca235f", "rules missing in recovery mode"),
  ])
  #expect(fetchDefaultRulesInvocations.value == 1)
  #expect(savedProtectionModes.value == [.normal([.urlContains(value: "default-from-api")])])
  #expect(filterNotifications.value == [.rulesChanged])
  #expect(recoveryDirectiveInvocations.value == 1)
  #expect(dismissInvocations.value == 1)
}

@MainActor
@Test func unconnectedRecoveryWithMissingRulesFailedFetch() async throws {
  let apiLoggedEvents = LockIsolated<[Both<String, String?>]>([])
  let savedProtectionModes = LockIsolated<[ProtectionMode]>([])
  let fetchDefaultRulesInvocations = LockIsolated(0)
  let filterNotifications = LockIsolated<[FilterClient.Notification]>([])

  let store = TestStore(initialState: InfoFeature.State(connection: nil)) {
    InfoFeature()
  } withDependencies: {
    $0.device.vendorId = { UUID(1) }
    $0.api.logEvent = { @Sendable id, detail in
      apiLoggedEvents.withValue { $0.append(Both(id, detail)) }
    }
    $0.sharedStorage.loadDisabledBlockGroups = { @Sendable in [] }
    $0.sharedStorage.saveDisabledBlockGroups = { @Sendable _ in
      fatalError("saveDisabledBlockGroups should not be called")
    }
    $0.sharedStorage.loadProtectionMode = { @Sendable in
      .normal([])
    }
    $0.sharedStorage.saveProtectionMode = { @Sendable mode in
      savedProtectionModes.withValue { $0.append(mode) }
    }
    $0.api.fetchDefaultBlockRules = { @Sendable vid in
      fetchDefaultRulesInvocations.withValue { $0 += 1 }
      struct TestError: Error {}
      throw TestError()
    }
    $0.filter.send = { @Sendable notification in
      filterNotifications.withValue { $0.append(notification) }
    }
    $0.api.recoveryDirective = { @Sendable in nil }
    $0.dismiss = .init {}
  }

  await store.shake(times: 5)
  await store.send(.receivedShake) { $0.timesShaken = 0 }

  #expect(apiLoggedEvents.value == [
    Both("a8998540", "entering recovery mode"),
    Both("bcca235f", "rules missing in recovery mode"),
    Both("2c3a4481", "failed to fetch defaults in recovery mode"),
  ])
  #expect(fetchDefaultRulesInvocations.value == 1)
  #expect(savedProtectionModes.value.count == 1)
  if case .normal(let rules) = savedProtectionModes.value.first {
    #expect(!rules.isEmpty)
  } else {
    Issue.record("Expected .normal protection mode with hardcoded defaults")
  }
  #expect(filterNotifications.value == [.rulesChanged])
}

@MainActor
@Test func unconnectedRecoveryWithRetryDirective() async throws {
  let apiLoggedEvents = LockIsolated<[Both<String, String?>]>([])
  let filterNotifications = LockIsolated<[FilterClient.Notification]>([])
  let recoveryDirectiveInvocations = LockIsolated(0)
  let cleanupForRetryInvocations = LockIsolated(0)
  let dismissInvocations = LockIsolated(0)

  let store = TestStore(initialState: InfoFeature.State(connection: nil)) {
    InfoFeature()
  } withDependencies: {
    $0.api.logEvent = { @Sendable id, detail in
      apiLoggedEvents.withValue { $0.append(Both(id, detail)) }
    }
    $0.sharedStorage.loadDisabledBlockGroups = { @Sendable in [] }
    $0.sharedStorage.saveDisabledBlockGroups = { @Sendable _ in
      fatalError("saveDisabledBlockGroups should not be called")
    }
    $0.sharedStorage.saveProtectionMode = { @Sendable _ in
      fatalError("saveProtectionMode should not be called")
    }
    $0.sharedStorage.loadProtectionMode = { @Sendable in
      .normal([.urlContains(value: "existing")])
    }
    $0.filter.send = { @Sendable notification in
      filterNotifications.withValue { $0.append(notification) }
    }
    $0.api.recoveryDirective = { @Sendable in
      recoveryDirectiveInvocations.withValue { $0 += 1 }
      return "retry" // <-- triggers cleanupForRetry
    }
    $0.systemExtension.cleanupForRetry = { @Sendable in
      cleanupForRetryInvocations.withValue { $0 += 1 }
    }
    $0.dismiss = .init {
      dismissInvocations.withValue { $0 += 1 }
    }
  }

  await store.shake(times: 5)
  await store.send(.receivedShake) { $0.timesShaken = 0 }

  #expect(apiLoggedEvents.value == [
    Both("a8998540", "entering recovery mode"),
    Both("aeaa467d", "received retry directive"),
  ])
  #expect(filterNotifications.value == [.rulesChanged])
  #expect(recoveryDirectiveInvocations.value == 1)
  #expect(cleanupForRetryInvocations.value == 1)
  #expect(dismissInvocations.value == 1)
}

@MainActor
@Test func unconnectedRecoveryDoesNotTriggerWhenConnected() async throws {
  let apiLoggedEvents = LockIsolated<[Both<String, String?>]>([])
  let recoveryDirectiveInvocations = LockIsolated(0)
  let dismissInvocations = LockIsolated(0)

  let store = TestStore(initialState: InfoFeature.State(
    connection: ChildIOSDeviceData_b1(
      childId: UUID(),
      token: UUID(),
      deviceId: UUID(),
      childName: "Test Child",
    ),
    vendorId: UUID(),
  )) {
    InfoFeature()
  } withDependencies: {
    $0.api.logEvent = { @Sendable id, detail in
      apiLoggedEvents.withValue { $0.append(Both(id, detail)) }
    }
    $0.sharedStorage.loadDisabledBlockGroups = { @Sendable in
      fatalError("loadDisabledBlockGroups should not be called")
    }
    $0.sharedStorage.saveDisabledBlockGroups = { @Sendable _ in
      fatalError("saveDisabledBlockGroups should not be called")
    }
    $0.sharedStorage.loadProtectionMode = { @Sendable in
      fatalError("loadProtectionMode should not be called")
    }
    $0.sharedStorage.saveProtectionMode = { @Sendable _ in
      fatalError("saveProtectionMode should not be called")
    }
    $0.filter.send = { @Sendable _ in
      fatalError("filter.send should not be called")
    }
    $0.api.recoveryDirective = { @Sendable in
      recoveryDirectiveInvocations.withValue { $0 += 1 }
      return nil
    }
    $0.systemExtension.cleanupForRetry = { @Sendable in
      fatalError("cleanupForRetry should not be called")
    }
    $0.dismiss = .init {
      dismissInvocations.withValue { $0 += 1 }
    }
  }

  await store.shake(times: 5)
  await store.send(.receivedShake) { $0.timesShaken = 0 }

  #expect(apiLoggedEvents.value.isEmpty)
  #expect(recoveryDirectiveInvocations.value == 1)
  #expect(dismissInvocations.value == 1)
}

@MainActor
@Test func ensureUnconnectedRulesWithGoodData() async throws {
  let savedProtectionModes = LockIsolated<[ProtectionMode]>([])
  let fetchBlockRulesInvocations = LockIsolated(0)
  let filterNotifications = LockIsolated<[FilterClient.Notification]>([])
  let loadDisabledBlockGroupsInvocations = LockIsolated(0)
  let vendorId = UUID(1)

  let store = TestStore(initialState: InfoFeature.State(
    connection: nil,
    vendorId: vendorId,
  )) {
    InfoFeature()
  } withDependencies: {
    $0.api.logEvent = { @Sendable _, _ in
      fatalError("logEvent should not be called")
    }
    $0.sharedStorage.loadDisabledBlockGroups = { @Sendable in
      loadDisabledBlockGroupsInvocations.withValue { $0 += 1 }
      return [.whatsAppFeatures]
    }
    $0.sharedStorage.saveDisabledBlockGroups = { @Sendable _ in
      fatalError("saveDisabledBlockGroups should not be called")
    }
    $0.sharedStorage.saveProtectionMode = { @Sendable mode in
      savedProtectionModes.withValue { $0.append(mode) }
    }
    $0.api.fetchBlockRules = { @Sendable vid, disabledGroups in
      #expect(vid == vendorId)
      #expect(disabledGroups == [.whatsAppFeatures])
      fetchBlockRulesInvocations.withValue { $0 += 1 }
      return [.urlContains(value: "fetched-rule")]
    }
    $0.filter.send = { @Sendable notification in
      filterNotifications.withValue { $0.append(notification) }
    }
    $0.osLog.log = { @Sendable _ in }
  }

  await store.send(.sheetPresented)

  #expect(loadDisabledBlockGroupsInvocations.value == 1)
  #expect(fetchBlockRulesInvocations.value == 1)
  #expect(savedProtectionModes.value == [.normal([.urlContains(value: "fetched-rule")])])
  #expect(filterNotifications.value == [.rulesChanged])
}

@MainActor
@Test func ensureUnconnectedRulesWithMissingDisabledBlockGroups() async throws {
  let apiLoggedEvents = LockIsolated<[Both<String, String?>]>([])
  let savedDisabledBlockGroups = LockIsolated<[[BlockGroup]]>([])
  let savedProtectionModes = LockIsolated<[ProtectionMode]>([])
  let fetchBlockRulesInvocations = LockIsolated(0)
  let filterNotifications = LockIsolated<[FilterClient.Notification]>([])
  let vendorId = UUID(1)

  let store = TestStore(initialState: InfoFeature.State(
    connection: nil,
    vendorId: vendorId,
  )) {
    InfoFeature()
  } withDependencies: {
    $0.api.logEvent = { @Sendable id, detail in
      apiLoggedEvents.withValue { $0.append(Both(id, detail)) }
    }
    $0.sharedStorage.loadDisabledBlockGroups = { @Sendable in
      nil
    }
    $0.sharedStorage.saveDisabledBlockGroups = { @Sendable groups in
      savedDisabledBlockGroups.withValue { $0.append(groups) }
    }
    $0.sharedStorage.saveProtectionMode = { @Sendable mode in
      savedProtectionModes.withValue { $0.append(mode) }
    }
    $0.api.fetchBlockRules = { @Sendable vid, disabledGroups in
      #expect(vid == vendorId)
      #expect(disabledGroups == [])
      fetchBlockRulesInvocations.withValue { $0 += 1 }
      return [.urlContains(value: "fetched-rule")]
    }
    $0.filter.send = { @Sendable notification in
      filterNotifications.withValue { $0.append(notification) }
    }
    $0.osLog.log = { @Sendable _ in }
  }

  await store.send(.sheetPresented)

  #expect(savedDisabledBlockGroups.value == [[]]) // <-- saved empty disabled block groups
  #expect(apiLoggedEvents.value == [Both("59d3c6d1", "UNEXPECTED no stored disabled block groups")])
  #expect(fetchBlockRulesInvocations.value == 1)
  #expect(savedProtectionModes.value == [.normal([.urlContains(value: "fetched-rule")])])
  #expect(filterNotifications.value == [.rulesChanged])
}

@Test func testMissingRules() {
  var mode: ProtectionMode? = .onboarding([])
  #expect(mode.missingRules)
  mode = .emergencyLockdown
  #expect(mode.missingRules)
  mode = .normal([])
  #expect(mode.missingRules)
  mode = nil
  #expect(mode.missingRules)
  mode = .onboarding([.urlContains(value: "default-rule")])
  #expect(!mode.missingRules)
  mode = .normal([.urlContains(value: "some-rule")])
  #expect(!mode.missingRules)
}

public struct Both<A: Equatable & Sendable, B: Equatable & Sendable>: Equatable, Sendable {
  public var a: A
  public var b: B
  public init(_ a: A, _ b: B) {
    self.a = a
    self.b = b
  }
}

extension TestStoreOf<InfoFeature> {
  func shake(times: Int) async {
    for _ in 0 ..< times {
      await self.send(.receivedShake) {
        $0.timesShaken += 1
      }
    }
  }
}
