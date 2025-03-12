import Combine
import ComposableArchitecture
import GertieIOS
import LibClients
import LibCore
import XCTest
import XExpect

@testable import LibApp

enum SavedCodable: Equatable {
  case protectionMode(ProtectionMode)
  case disabledBlockGroups([BlockGroup])
}

final class IOSReducerTests: XCTestCase {
  func testHappyPath() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let requestAuthInvocations = LockIsolated(0)
    let installInvocations = LockIsolated(0)
    let deleteCacheFillDirInvocations = LockIsolated(0)
    let batteryCheckInvocations = LockIsolated(0)
    let ratingRequestInvocations = LockIsolated(0)
    let defaultBlocksInvocations = LockIsolated(0)
    let fetchBlockRulesInvocations = LockIsolated(0)
    let storedDates = LockIsolated<[Date]>([])
    let storedCodables = LockIsolated<[SavedCodable]>([])
    let cacheClearSubject = PassthroughSubject<DeviceClient.ClearCacheUpdate, Never>()
    let vendorId = UUID()

    let store = await TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.date = .constant(.reference)
      $0.mainQueue = .immediate
      $0.locale = Locale(identifier: "en_US")
      $0.api.logEvent = { @Sendable _, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.api.fetchDefaultBlockRules = { @Sendable _ in
        defaultBlocksInvocations.withValue { $0 += 1 }
        return [.urlContains("default-rule")]
      }
      $0.api.fetchBlockRules = { @Sendable vid, disabled in
        expect(vid).toEqual(vendorId)
        expect(disabled).toEqual([.appleMapsImages])
        fetchBlockRulesInvocations.withValue { $0 += 1 }
        return [.urlContains("GIFs")]
      }
      $0.systemExtension.requestAuthorization = {
        requestAuthInvocations.withValue { $0 += 1 }
        return .success(())
      }
      $0.systemExtension.filterRunning = { false }
      $0.systemExtension.installFilter = {
        installInvocations.withValue { $0 += 1 }
        return .success(())
      }
      $0.device.vendorId = vendorId
      $0.device.deleteCacheFillDir = {
        deleteCacheFillDirInvocations.withValue { $0 += 1 }
      }
      $0.device.batteryLevel = {
        batteryCheckInvocations.withValue { $0 += 1 }
        return .level(0.2)
      }
      $0.storage.loadDate = { @Sendable _ in nil }
      $0.storage.loadData = { @Sendable _ in nil }
      $0.storage.saveDate = { @Sendable value, key in
        assert(key == .launchDateStorageKey)
        storedDates.withValue { $0.append(value) }
      }
      $0.storage.saveCodable = { @Sendable value, key in
        switch key {
        case .disabledBlockGroupsStorageKey:
          storedCodables.withValue { $0.append(.disabledBlockGroups(value as! [BlockGroup])) }
        case .protectionModeStorageKey:
          storedCodables.withValue { $0.append(.protectionMode(value as! ProtectionMode)) }
        default:
          fatalError("unexpected key: \(key)")
        }
      }
      $0.device.clearCache = { _ in
        cacheClearSubject.eraseToAnyPublisher()
      }
      $0.device.availableDiskSpaceInBytes = { 1024 * 12 }
      $0.appStore.requestRating = {
        ratingRequestInvocations.withValue { $0 += 1 }
      }
    }

    await store.send(.programmatic(.appDidLaunch))

    await store.receive(.programmatic(.setFirstLaunch(.reference))) {
      $0.onboarding.firstLaunch = .reference
    }

    await store.receive(.programmatic(.setScreen(.onboarding(.happyPath(.hiThere))))) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }

    expect(storedDates.value).toEqual([.reference])
    expect(apiLoggedDetails.value).toEqual(["[onboarding] first launch, region: `US`"])
    expect(deleteCacheFillDirInvocations.value).toEqual(1)
    expect(defaultBlocksInvocations.value).toEqual(1)
    expect(storedCodables.value).toEqual([
      .protectionMode(.onboarding([.urlContains("default-rule")])),
    ])

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.timeExpectation))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmChildsDevice))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.explainMinorOrSupervised))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmMinorDevice))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmParentIsOnboarding))
    }

    // resume
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmInAppleFamily))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.explainAuthWithParentAppleAccount))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.dontGetTrickedPreAuth))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store.receive(.programmatic(.authorizationSucceeded)) {
      $0.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    }

    expect(requestAuthInvocations.value).toEqual(1)
    expect(apiLoggedDetails.value).toEqual([
      "[onboarding] first launch, region: `US`",
      "[onboarding] authorization succeeded",
    ])

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.dontGetTrickedPreInstall))
    }

    expect(storedCodables.value.count).toEqual(1)
    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store.receive(.programmatic(.installSucceeded)) {
      $0.screen = .onboarding(.happyPath(.optOutBlockGroups))
    }

    expect(installInvocations.value).toEqual(1)
    expect(apiLoggedDetails.value).toEqual([
      "[onboarding] first launch, region: `US`",
      "[onboarding] authorization succeeded",
      "[onboarding] filter install success",
    ])

    expect(storedCodables.value).toEqual([
      .protectionMode(.onboarding([.urlContains("default-rule")])),
      // we save empty on first load of screen, in case they quit before clicking next
      // if they did, it would confuse the app to think they were in supervised mode
      .disabledBlockGroups([]),
    ])

    await store.send(.interactive(.blockGroupToggled(.whatsAppFeatures))) {
      $0.disabledBlockGroups = [.whatsAppFeatures]
    }

    await store.send(.interactive(.blockGroupToggled(.whatsAppFeatures))) {
      $0.disabledBlockGroups = []
    }

    await store.send(.interactive(.blockGroupToggled(.appleMapsImages))) {
      $0.disabledBlockGroups = [.appleMapsImages]
    }

    expect(storedCodables.value.count).toEqual(2)

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) { // <-- "Done" from groups
      $0.screen = .onboarding(.happyPath(.promptClearCache))
    }

    expect(fetchBlockRulesInvocations.value).toEqual(1)

    expect(storedCodables.value).toEqual([
      .protectionMode(.onboarding([.urlContains("default-rule")])),
      .disabledBlockGroups([]), // <-- on opt-out groups screen load, failsafe
      .disabledBlockGroups([.appleMapsImages]), // <-- persist user choice after "Done"
      .protectionMode(.normal([.urlContains("GIFs")])), // <-- got customized rules from api
    ])

    await store.receive(.programmatic(.setAvailableDiskSpaceInBytes(1024 * 12))) {
      $0.onboarding.availableDiskSpaceInBytes = 1024 * 12
    }

    await store.receive(.programmatic(.setBatteryLevel(.level(0.2)))) {
      $0.onboarding.batteryLevel = .level(0.2)
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.batteryWarning))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.onboarding.startClearCache = .reference
      $0.screen = .onboarding(.happyPath(.clearingCache(0)))
    }

    cacheClearSubject.send(.bytesCleared(1024))
    await store.receive(.programmatic(.receiveClearCacheUpdate(.bytesCleared(1024)))) {
      $0.screen = .onboarding(.happyPath(.clearingCache(1024)))
    }

    cacheClearSubject.send(.finished)
    await store.receive(.programmatic(.receiveClearCacheUpdate(.finished))) {
      $0.onboarding.endClearCache = .reference
      $0.screen = .onboarding(.happyPath(.cacheCleared))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.requestAppStoreRating))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.doneQuit))
    }

    expect(ratingRequestInvocations.value).toEqual(1)
  }

  func testUpgradeFromV110() async throws {
    let defaultBlocksInvocations = LockIsolated(0)
    let storedCodables = LockIsolated<[SavedCodable]>([])
    let removeObjectInvocations = LockIsolated<[String]>([])
    let notifyFilterInvocations = LockIsolated(0)

    let store = await TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.api.logEvent = { @Sendable _, _ in }
      $0.api.fetchDefaultBlockRules = { @Sendable _ in
        defaultBlocksInvocations.withValue { $0 += 1 }
        return [.urlContains("GIFs")]
      }
      $0.storage.removeObject = { @Sendable key in
        removeObjectInvocations.withValue { $0.append(key) }
      }
      $0.systemExtension.filterRunning = { true } // <-- filter running
      $0.storage.loadDate = { @Sendable _ in .reference } // <-- v1.1.0 launch date
      $0.storage.loadData = { @Sendable key in
        if key == .legacyStorageKey {
          return "[]".data(using: .utf8) // <-- has V1 legacy data
        } else {
          return nil
        }
      }
      $0.storage.saveCodable = { @Sendable value, key in
        switch key {
        case .disabledBlockGroupsStorageKey:
          storedCodables.withValue { $0.append(.disabledBlockGroups(value as! [BlockGroup])) }
        case .protectionModeStorageKey:
          storedCodables.withValue { $0.append(.protectionMode(value as! ProtectionMode)) }
        default:
          fatalError("unexpected key: \(key)")
        }
      }
      $0.filter.notifyRulesChanged = {
        notifyFilterInvocations.withValue { $0 += 1 }
      }
    }

    await store.send(.programmatic(.appDidLaunch))

    await store.receive(.programmatic(.setFirstLaunch(.reference))) {
      $0.onboarding.firstLaunch = .reference
    }

    await store.receive(.programmatic(.setScreen(.running(showVendorId: false)))) {
      $0.screen = .running(showVendorId: false)
    }

    expect(removeObjectInvocations.value).toEqual([.legacyStorageKey])
    expect(defaultBlocksInvocations.value).toEqual(1)
    expect(notifyFilterInvocations.value).toEqual(1)
    expect(storedCodables.value).toEqual([
      .disabledBlockGroups([]),
      .protectionMode(.normal([.urlContains("GIFs")])),
    ])
  }

  @MainActor
  func testUsesHardcodedBlockRulesIfApiDefaultsReqFails() async throws {
    let storedCodables = LockIsolated<[ProtectionMode]>([])

    let store = TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.date = .constant(.reference)
      $0.locale = Locale(identifier: "en_US")
      $0.device.deleteCacheFillDir = {}
      $0.api.logEvent = { @Sendable _, _ in }
      $0.api.fetchDefaultBlockRules = { @Sendable _ in
        struct TestError: Error {}
        throw TestError()
      }
      $0.storage.loadDate = { @Sendable _ in nil }
      $0.storage.loadData = { @Sendable _ in nil }
      $0.storage.saveDate = { @Sendable _, _ in }
      $0.storage.saveCodable = { @Sendable value, key in
        switch key {
        case .protectionModeStorageKey:
          storedCodables.withValue { $0.append(value as! ProtectionMode) }
        default:
          fatalError("unexpected key: \(key)")
        }
      }
    }

    store.exhaustivity = .off
    await store.send(.programmatic(.appDidLaunch))

    expect(storedCodables.value).toEqual([.onboarding(BlockRule.defaults)])
  }

  func testChooseWriteReview() async throws {
    let writeReviewInvocations = LockIsolated(0)
    let store = await TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.requestAppStoreRating)))
    ) {
      IOSReducer()
    } withDependencies: {
      $0.appStore.requestReview = {
        writeReviewInvocations.withValue { $0 += 1 }
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.happyPath(.doneQuit))
    }

    expect(writeReviewInvocations.value).toEqual(1)
  }

  func testSkipReviewAndRating() async throws {
    let store = store(starting: .onboarding(.happyPath(.requestAppStoreRating)))
    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.screen = .onboarding(.happyPath(.doneQuit))
    }
  }

  func testSkipsBatteryWarningWhenEnough() async throws {
    let clearCacheInvocations = LockIsolated(0)
    let store = await TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.happyPath(.promptClearCache)),
      onboarding: .init(
        batteryLevel: .level(0.75), // <-- enough battery
        availableDiskSpaceInBytes: 1024 * 1024 * 1024 * 5 // <-- 5 GB space
      )
    )) {
      IOSReducer()
    } withDependencies: {
      $0.mainQueue = .immediate
      $0.date = .constant(.reference)
      $0.device.clearCache = { _ in
        clearCacheInvocations.withValue { $0 += 1 }
        return AnyPublisher(Empty())
      }
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.onboarding.startClearCache = .reference
      $0.screen = .onboarding(.happyPath(.clearingCache(0)))
    }
    expect(clearCacheInvocations.value).toEqual(1)
  }

  func testShowsBatteryWarningWhenHugeDiskToClear() async throws {
    let clearCacheInvocations = LockIsolated(0)
    let store = await TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.happyPath(.promptClearCache)),
      onboarding: .init(
        batteryLevel: .level(0.95), // <-- lots of battery, but...
        availableDiskSpaceInBytes: 1024 * 1024 * 1024 * 65 // ...65 GB to clear !!
      )
    )) {
      IOSReducer()
    } withDependencies: {
      $0.mainQueue = .immediate
      $0.date = .constant(.reference)
      $0.device.clearCache = { _ in
        clearCacheInvocations.withValue { $0 += 1 }
        return AnyPublisher(Empty())
      }
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.batteryWarning))
    }
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.onboarding.startClearCache = .reference
      $0.screen = .onboarding(.happyPath(.clearingCache(0)))
    }
    expect(clearCacheInvocations.value).toEqual(1)
  }

  func testFirstLaunchWithStoredDate_ToRunning() async throws {
    let store = await TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.device.deleteCacheFillDir = {}
      $0.api.fetchDefaultBlockRules = { @Sendable _ in [] }
      $0.storage.saveCodable = { @Sendable _, _ in }
      $0.storage.loadDate = { @Sendable _ in .distantPast }
      $0.storage.loadData = { @Sendable _ in "[]".data(using: .utf8) }
      $0.systemExtension.filterRunning = { true }
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.distantPast))) {
      $0.onboarding.firstLaunch = .distantPast
    }
    await store.receive(.programmatic(.setScreen(.running(showVendorId: false)))) {
      $0.screen = .running(showVendorId: false)
    }
  }

  func testRunningShake() async throws {
    let fetchRulesInvocations = LockIsolated(0)
    let saveDataInvocations = LockIsolated<[ProtectionMode]>([])
    let notifyFilterInvocations = LockIsolated(0)
    let vendorId = UUID()
    let store = await TestStore(
      initialState: IOSReducer.State(screen: .running(showVendorId: false))
    ) {
      IOSReducer()
    } withDependencies: {
      $0.device.vendorId = vendorId
      $0.storage.loadData = { @Sendable key in
        expect(key).toBe(.disabledBlockGroupsStorageKey)
        return try! JSONEncoder().encode([BlockGroup.whatsAppFeatures])
      }
      $0.api.fetchBlockRules = { @Sendable vid, disabled in
        expect(vid).toEqual(vendorId)
        expect(disabled).toEqual([.whatsAppFeatures])
        fetchRulesInvocations.withValue { $0 += 1 }
        return [.urlContains("GIFs")]
      }
      $0.storage.saveCodable = { @Sendable value, key in
        expect(key).toEqual(.protectionModeStorageKey)
        saveDataInvocations.withValue { $0.append(value as! ProtectionMode) }
      }
      $0.filter.notifyRulesChanged = {
        notifyFilterInvocations.withValue { $0 += 1 }
      }
    }

    await store.send(.interactive(.receivedShake)) {
      $0.screen = .running(showVendorId: true)
    }
    expect(fetchRulesInvocations.value).toEqual(1)
    expect(saveDataInvocations.value).toEqual([.normal([.urlContains("GIFs")])])
    expect(notifyFilterInvocations.value).toEqual(1)
  }

  func testFirstLaunchSupervisedSuccess() async throws {
    let store = await TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.date = .constant(.reference)
      $0.locale = Locale(identifier: "en_US")
      $0.device.deleteCacheFillDir = {}
      $0.api.fetchDefaultBlockRules = { @Sendable _ in [] }
      $0.api.logEvent = { @Sendable _, _ in }
      $0.storage.saveCodable = { @Sendable _, _ in }
      $0.storage.saveDate = { @Sendable _, _ in }
      $0.storage.loadDate = { @Sendable _ in nil }
      $0.systemExtension.filterRunning = { true } // <-- filter running
      $0.storage.loadData = { @Sendable _ in nil } // <-- but no sign of onboarding...
    }

    await store.send(.programmatic(.appDidLaunch))
    await store.receive(.programmatic(.setFirstLaunch(.reference))) {
      $0.onboarding.firstLaunch = .reference
    }
    // ...so we go straight to supervision first launch
    await store.receive(.programmatic(.setScreen(.supervisionSuccessFirstLaunch))) {
      $0.screen = .supervisionSuccessFirstLaunch
    }

    // primary button goes to opt out groups
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.optOutBlockGroups))
    }
  }

  func testParentDeviceFail() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmChildsDevice)))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.onParentDeviceFail)
    }
  }

  func testCantAdvanceWithZeroBlockGroups() async throws {
    let store = await TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.happyPath(.optOutBlockGroups)),
      disabledBlockGroups: .all // <-- deselected all
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    await expect(store.state.screen).toEqual(.onboarding(.happyPath(.optOutBlockGroups)))
  }

  func testConfirmParentIsOnboardingFail() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmParentIsOnboarding)))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.childIsOnboardingFail)
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }
  }

  func testSkipCacheClear() async throws {
    let store = store(starting: .onboarding(.happyPath(.promptClearCache)))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.happyPath(.requestAppStoreRating))
    }
  }
}

func store(starting screen: IOSReducer.Screen) -> TestStore<IOSReducer.State, IOSReducer.Action> {
  TestStore(initialState: IOSReducer.State(screen: screen)) {
    IOSReducer()
  }
}

extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}
