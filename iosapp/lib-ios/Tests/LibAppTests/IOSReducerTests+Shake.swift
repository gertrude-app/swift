import ComposableArchitecture
import LibClients
import LibCore
import XCTest
import XExpect

@testable import LibApp

final class IOSReducerTestsShake: XCTestCase {
  // @MainActor
  // func testRunningShake() async throws {
  //   let fetchRulesInvocations = LockIsolated(0)
  //   let saveDataInvocations = LockIsolated<[ProtectionMode]>([])
  //   let notifyFilterInvocations = LockIsolated(0)
  //   let vendorId = UUID()
  //   let store = TestStore(
  //     initialState: IOSReducer.State(screen: .running(showVendorId: false))
  //   ) {
  //     IOSReducer()
  //   } withDependencies: {
  //     $0.device.vendorId = { vendorId }
  //     $0.storage.loadData = { @Sendable key in
  //       expect(key).toBe(.disabledBlockGroupsStorageKey)
  //       return try! JSONEncoder().encode([BlockGroup.whatsAppFeatures])
  //     }
  //     $0.api.fetchBlockRules = { @Sendable vid, disabled in
  //       expect(vid).toEqual(vendorId)
  //       expect(disabled).toEqual([.whatsAppFeatures])
  //       fetchRulesInvocations.withValue { $0 += 1 }
  //       return [.urlContains("GIFs")]
  //     }
  //     $0.storage.saveCodable = { @Sendable value, key in
  //       expect(key).toEqual(.protectionModeStorageKey)
  //       saveDataInvocations.withValue { $0.append(value as! ProtectionMode) }
  //     }
  //     $0.filter.notifyRulesChanged = {
  //       notifyFilterInvocations.withValue { $0 += 1 }
  //     }
  //   }

  //   await store.send(.interactive(.receivedShake)) {
  //     $0.screen = .running(showVendorId: true, timesShaken: 1)
  //   }
  //   expect(fetchRulesInvocations.value).toEqual(1)
  //   expect(saveDataInvocations.value).toEqual([.normal([.urlContains("GIFs")])])
  //   expect(notifyFilterInvocations.value).toEqual(1)
  // }

  // @MainActor
  // func testRunningShakeRequestsRulesEvenWhenMissingData() async throws {
  //   let fetchRulesInvocations = LockIsolated(0)
  //   let saveDataInvocations = LockIsolated<[SavedCodable]>([])
  //   let notifyFilterInvocations = LockIsolated(0)
  //   let loadDataInvocations = LockIsolated(0)
  //   let vendorId = UUID()
  //   let store = TestStore(
  //     initialState: IOSReducer.State(screen: .running(showVendorId: false))
  //   ) {
  //     IOSReducer()
  //   } withDependencies: {
  //     $0.device.vendorId = { vendorId }
  //     $0.storage.loadData = { @Sendable key in
  //       expect(key).toBe(.disabledBlockGroupsStorageKey)
  //       loadDataInvocations.withValue { $0 += 1 }
  //       return nil // <-- unexpected missing data...
  //     }
  //     $0.api.fetchBlockRules = { @Sendable vid, disabled in
  //       expect(vid).toEqual(vendorId)
  //       expect(disabled).toEqual([]) // <- ...so we request with no disabled groups
  //       fetchRulesInvocations.withValue { $0 += 1 }
  //       return [.urlContains("GIFs")]
  //     }
  //     $0.storage.saveCodable = { @Sendable value, key in
  //       saveDataInvocations.withValue { invocations in
  //         switch invocations.count {
  //         case 0:
  //           expect(key).toEqual(.disabledBlockGroupsStorageKey)
  //           invocations.append(.disabledBlockGroups(value as! [BlockGroup]))
  //         default:
  //           expect(key).toEqual(.protectionModeStorageKey)
  //           invocations.append(.protectionMode(value as! ProtectionMode))
  //         }
  //       }
  //     }
  //     $0.filter.notifyRulesChanged = {
  //       notifyFilterInvocations.withValue { $0 += 1 }
  //     }
  //   }

  //   await store.send(.interactive(.receivedShake)) {
  //     $0.screen = .running(showVendorId: true, timesShaken: 1)
  //   }
  //   expect(fetchRulesInvocations.value).toEqual(1)
  //   expect(saveDataInvocations.value).toEqual([
  //     .disabledBlockGroups([]), // <-- we write no opt-outs to disk to recover
  //     .protectionMode(.normal([.urlContains("GIFs")])),
  //   ])
  //   expect(notifyFilterInvocations.value).toEqual(1)
  // }

  // @MainActor
  // func testRecoveryModeNoRetry() async throws {
  //   let saveDataInvocations = LockIsolated<[SavedCodable]>([])
  //   let notifyFilterInvocations = LockIsolated(0)
  //   let loadDataInvocations = LockIsolated<[String]>([])
  //   let defaultBlocksInvocations = LockIsolated(0)
  //   let recoveryDirectiveInvocations = LockIsolated(0)
  //   let vendorId = UUID()
  //   let store = TestStore(
  //     // we start in the mode where they have already shaken
  //     initialState: IOSReducer.State(screen: .running(showVendorId: true, timesShaken: 1))
  //   ) {
  //     IOSReducer()
  //   } withDependencies: {
  //     $0.device.vendorId = { vendorId }
  //     $0.storage.loadData = { @Sendable key in
  //       loadDataInvocations.withValue { $0.append(key) }
  //       return nil // <-- unexpected missing data...
  //     }
  //     $0.storage.saveCodable = { @Sendable value, key in
  //       saveDataInvocations.withValue { invocations in
  //         switch invocations.count {
  //         case 0:
  //           expect(key).toEqual(.disabledBlockGroupsStorageKey)
  //           invocations.append(.disabledBlockGroups(value as! [BlockGroup]))
  //         default:
  //           expect(key).toEqual(.protectionModeStorageKey)
  //           invocations.append(.protectionMode(value as! ProtectionMode))
  //         }
  //       }
  //     }
  //     $0.filter.notifyRulesChanged = {
  //       notifyFilterInvocations.withValue { $0 += 1 }
  //     }
  //     $0.api.fetchDefaultBlockRules = { @Sendable _ in
  //       defaultBlocksInvocations.withValue { $0 += 1 }
  //       return [.urlContains("default-rule")]
  //     }
  //     $0.api.recoveryDirective = {
  //       recoveryDirectiveInvocations.withValue { $0 += 1 }
  //       return nil
  //     }
  //   }

  //   for i in 2 ... 5 {
  //     await store.send(.interactive(.receivedShake)) {
  //       $0.screen = .running(showVendorId: true, timesShaken: i)
  //     }
  //   }
  //   await store.send(.interactive(.receivedShake)) {
  //     $0.screen = .running(showVendorId: false, timesShaken: 0)
  //   }

  //   expect(loadDataInvocations.value).toEqual([
  //     .disabledBlockGroupsStorageKey,
  //     .protectionModeStorageKey,
  //   ])
  //   expect(defaultBlocksInvocations.value).toEqual(1)
  //   expect(saveDataInvocations.value).toEqual([
  //     .disabledBlockGroups([]), // <-- we write no opt-outs to disk to recover
  //     .protectionMode(.normal([.urlContains("default-rule")])),
  //   ])
  //   expect(notifyFilterInvocations.value).toEqual(1)
  //   expect(recoveryDirectiveInvocations.value).toEqual(1)
  // }

  // @MainActor
  // func testRecoveryModeWithRetry() async throws {
  //   let recoveryDirectiveInvocations = LockIsolated(0)
  //   let retryInvocations = LockIsolated(0)
  //   let store = TestStore(
  //     // we start in the mode where they have already shaken
  //     initialState: IOSReducer.State(screen: .running(showVendorId: true, timesShaken: 5))
  //   ) {
  //     IOSReducer()
  //   } withDependencies: {
  //     $0.device.vendorId = { UUID() }
  //     $0.storage.loadData = { @Sendable _ in nil }
  //     $0.storage.saveCodable = { @Sendable _, _ in }
  //     $0.filter.notifyRulesChanged = {}
  //     $0.api.fetchDefaultBlockRules = { @Sendable _ in [] }
  //     $0.api.recoveryDirective = {
  //       recoveryDirectiveInvocations.withValue { $0 += 1 }
  //       return "retry"
  //     }
  //     $0.systemExtension.cleanupForRetry = { @Sendable in
  //       retryInvocations.withValue { $0 += 1 }
  //     }
  //   }

  //   await store.send(.interactive(.receivedShake)) {
  //     $0.screen = .running(showVendorId: false, timesShaken: 0)
  //   }

  //   expect(recoveryDirectiveInvocations.value).toEqual(1)
  //   expect(retryInvocations.value).toEqual(1)
  // }

  func testMissingRules() {
    var mode: ProtectionMode? = .onboarding([])
    expect(mode.missingRules).toEqual(true)
    mode = .emergencyLockdown
    expect(mode.missingRules).toEqual(true)
    mode = .normal([])
    expect(mode.missingRules).toEqual(true)
    mode = nil
    expect(mode.missingRules).toEqual(true)
    mode = .onboarding([.urlContains(value: "default-rule")])
    expect(mode.missingRules).toEqual(false)
    mode = .normal([.urlContains(value: "some-rule")])
    expect(mode.missingRules).toEqual(false)
  }
}
