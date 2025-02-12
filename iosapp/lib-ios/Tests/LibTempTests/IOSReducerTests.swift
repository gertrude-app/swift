import Combine
import ComposableArchitecture
import LibClients
import XCTest
import XExpect

@testable import LibTemp

final class IOSReducerTests: XCTestCase {
  func testHappyPath() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let requestAuthInvocations = LockIsolated(0)
    let installInvocations = LockIsolated(0)
    let batteryCheckInvocations = LockIsolated(0)
    let ratingRequestInvocations = LockIsolated(0)
    let storedDates = LockIsolated<[Date]>([])
    let cacheClearSubject = PassthroughSubject<DeviceClient.ClearCacheUpdate, Never>()

    let store = await TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.date = .constant(.reference)
      $0.mainQueue = .immediate
      $0.locale = Locale(identifier: "en_US")
      $0.api.logEvent = { @Sendable _id, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.systemExtension.requestAuthorization = {
        requestAuthInvocations.withValue { $0 += 1 }
        return .success(())
      }
      $0.systemExtension.installFilter = {
        installInvocations.withValue { $0 += 1 }
        return .success(())
      }
      $0.device.batteryLevel = {
        batteryCheckInvocations.withValue { $0 += 1 }
        return .level(0.2)
      }
      $0.storage.loadDate = { @Sendable key in nil }
      $0.storage.saveDate = { @Sendable value, key in
        storedDates.withValue { $0.append(value) }
      }
      $0.device.clearCache = {
        cacheClearSubject.eraseToAnyPublisher()
      }
      $0.appStore.requestRating = {
        ratingRequestInvocations.withValue { $0 += 1 }
      }
    }

    await store.send(.appDidLaunch)

    await store.receive(.setFirstLaunch(.reference)) {
      $0.firstLaunch = .reference
    }

    expect(storedDates.value).toEqual([.reference])
    expect(apiLoggedDetails.value).toEqual(["first launch, region: `US`"])

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.timeExpectation))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.confirmChildsDevice))
    }

    await store.send(.happyPathBtnTapped) {
      $0.screen = .onboarding(.happyPath(.explainMinorOrSupervised))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.confirmMinorDevice))
    }

    await store.send(.happyPathBtnTapped) {
      $0.screen = .onboarding(.happyPath(.confirmParentIsOnboarding))
    }

    await store.send(.happyPathBtnTapped) {
      $0.screen = .onboarding(.happyPath(.confirmInAppleFamily))
    }

    await store.send(.happyPathBtnTapped) {
      $0.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.explainAuthWithParentAppleAccount))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.dontGetTrickedPreAuth))
    }

    await store.send(.onlyBtnTapped)

    await store.receive(.authorizationSucceeded) {
      $0.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    }

    expect(requestAuthInvocations.value).toEqual(1)
    expect(apiLoggedDetails.value).toEqual([
      "first launch, region: `US`",
      "authorization succeeded",
    ])

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.dontGetTrickedPreInstall))
    }

    await store.send(.onlyBtnTapped)

    await store.receive(.installSucceeded) {
      $0.screen = .onboarding(.happyPath(.optOutBlockGroups))
    }

    expect(installInvocations.value).toEqual(1)
    expect(apiLoggedDetails.value).toEqual([
      "first launch, region: `US`",
      "authorization succeeded",
      "filter install success",
    ])

    var expectedGroups = [BlockGroup].all.filter { $0 != .whatsAppFeatures }
    await store.send(.blockGroupToggled(.whatsAppFeatures)) {
      $0.blockGroups = expectedGroups
    }

    expectedGroups.append(.whatsAppFeatures)
    await store.send(.blockGroupToggled(.whatsAppFeatures)) {
      $0.blockGroups = expectedGroups
    }

    expectedGroups = expectedGroups.filter { $0 != .appleMapsImages }
    await store.send(.blockGroupToggled(.appleMapsImages)) {
      $0.blockGroups = expectedGroups
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.promptClearCache))
    }

    await store.receive(.setBatteryLevel(.level(0.2))) {
      $0.batteryLevel = .level(0.2)
    }

    await store.send(.primaryBtnTapped) {
      $0.screen = .onboarding(.happyPath(.batteryWarning))
    }

    await store.send(.primaryBtnTapped) {
      $0.screen = .onboarding(.happyPath(.clearingCache("")))
    }

    cacheClearSubject.send(.bytesCleared(1024))
    await store.receive(.receiveClearCacheUpdate(.bytesCleared(1024))) {
      $0.screen = .onboarding(.happyPath(.clearingCache("1024 bytes")))
    }

    cacheClearSubject.send(.completed)
    await store.receive(.receiveClearCacheUpdate(.completed)) {
      $0.screen = .onboarding(.happyPath(.cacheCleared))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.requestAppStoreRating))
    }

    await store.send(.primaryBtnTapped) {
      $0.screen = .onboarding(.happyPath(.doneQuit))
    }

    expect(ratingRequestInvocations.value).toEqual(1)
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

    await store.send(.secondaryBtnTapped) {
      $0.screen = .onboarding(.happyPath(.doneQuit))
    }

    expect(writeReviewInvocations.value).toEqual(1)
  }

  func testSkipReviewAndRating() async throws {
    let store = store(starting: .onboarding(.happyPath(.requestAppStoreRating)))
    await store.send(.tertiaryBtnTapped) {
      $0.screen = .onboarding(.happyPath(.doneQuit))
    }
  }

  func testSkipsBatteryWarningWhenEnough() async throws {
    let clearCacheInvocations = LockIsolated(0)
    let store = await TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.happyPath(.promptClearCache)),
      batteryLevel: .level(0.75) // <-- enough battery
    )) {
      IOSReducer()
    } withDependencies: {
      $0.mainQueue = .immediate
      $0.device.clearCache = {
        clearCacheInvocations.withValue { $0 += 1 }
        return AnyPublisher(Empty())
      }
    }
    await store.send(.primaryBtnTapped) {
      $0.screen = .onboarding(.happyPath(.clearingCache("")))
    }
    expect(clearCacheInvocations.value).toEqual(1)
  }

  func testFirstLaunchWithStoredDate() async throws {
    let store = await TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
      $0.storage.loadDate = { @Sendable key in .distantPast }
    }

    await store.send(.appDidLaunch)
    await store.receive(.setFirstLaunch(.distantPast)) {
      $0.firstLaunch = .distantPast
    }
  }

  func testParentDeviceFail() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmChildsDevice)))

    await store.send(.sadPathBtnTapped) {
      $0.screen = .onboarding(.onParentDeviceFail)
    }
  }

  func testCantAdvanceWithZeroBlockGroups() async throws {
    // 👉 TODO: should also disable button in view
    let store = await TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.happyPath(.optOutBlockGroups)),
      blockGroups: [] // <-- deselected all
    )) {
      IOSReducer()
    }

    await store.send(.onlyBtnTapped)
    await expect(store.state.screen).toEqual(.onboarding(.happyPath(.optOutBlockGroups)))
  }

  func testAuthFail() async throws {
    // TODO: test all variations of authentication failure/flow
    // test cleanup called on systemExtension, test api event logged, etc.
  }

  func testInstallFail() async throws {
    // TODO: test all variations of autiinstall failure/flow
    // test cleanup called on systemExtension, test api event logged, etc.
  }

  func testConfirmParentIsOnboardingFail() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmParentIsOnboarding)))

    await store.send(.sadPathBtnTapped) {
      $0.screen = .onboarding(.childIsOnboardingFail)
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.hiThere))
    }
  }

  func testAppleFamilyFailFlow1() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmInAppleFamily)))

    await store.send(.sadPathBtnTapped) {
      $0.screen = .onboarding(.appleFamily(.explainRequiredForFiltering))
    }

    // TODO: continue from here, w/ all permutations
  }

  func testAppleFamilyDontKnowFlow() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmInAppleFamily)))

    await store.send(.iDontKnowBtnTapped) {
      $0.screen = .onboarding(.appleFamily(.explainWhatIsAppleFamily))
    }

    // but from here do we need to help them figure out if they're already in one?
    // because they clicked "i don't know?"

    // TODO: continue from here, w/ all permutations
  }

  // TODO: check all tests from here, transfer/rewrite any missing/important ones:
  // https://github.com/gertrude-app/swift/blob/3b3b000e7fa63cc6c71fed21369114bc852c6dcf/iosapp/lib-ios/Tests/LibIOSTests/AppTests.swift
}

func store(starting screen: IOSReducer.Screen) -> TestStore<IOSReducer.State, IOSReducer.Action> {
  TestStore(initialState: IOSReducer.State(screen: screen)) {
    IOSReducer()
  }
}

// remove these
extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}
