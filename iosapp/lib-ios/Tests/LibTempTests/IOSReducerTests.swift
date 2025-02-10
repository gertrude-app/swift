import ComposableArchitecture
import XCTest
import XExpect

@testable import LibTemp

final class IOSReducerTests: XCTestCase {
  func testHappyPath() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let requestAuthInvocations = LockIsolated(0)
    let installInvocations = LockIsolated(0)

    let store = await TestStore(initialState: IOSReducer.State()) {
      IOSReducer()
    } withDependencies: {
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
    }

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
    expect(apiLoggedDetails.value).toEqual(["authorization succeeded"])

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.dontGetTrickedPreInstall))
    }

    await store.send(.onlyBtnTapped)

    await store.receive(.installSucceeded) {
      $0.screen = .onboarding(.happyPath(.optOutBlockGroups))
    }

    expect(installInvocations.value).toEqual(1)
    expect(apiLoggedDetails.value).toEqual(["authorization succeeded", "filter install success"])

    await store.send(.blockGroupToggled(.whatsAppFeatures)) {
      $0.blockGroups = .all.filter { $0 != .whatsAppFeatures }
    }

    await store.send(.blockGroupToggled(.whatsAppFeatures)) {
      var expected = [BlockGroup].all.filter { $0 != .whatsAppFeatures }
      expected.append(.whatsAppFeatures)
      $0.blockGroups = expected
    }
  }

  func testParentDeviceFail() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmChildsDevice)))

    await store.send(.sadPathBtnTapped) {
      $0.screen = .onboarding(.onParentDeviceFail)
    }
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
      $0.screen = .onboarding(.fixAppleFamily(.explainRequiredForFiltering))
    }

    // TODO: continue from here, w/ all permutations
  }

  func testAppleFamilyDontKnowFlow() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmInAppleFamily)))

    await store.send(.iDontKnowBtnTapped) {
      $0.screen = .onboarding(.fixAppleFamily(.explainWhatIsAppleFamily))
    }

    // but from here do we need to help them figure out if they're already in one?
    // because they clicked "i don't know?"

    // TODO: continue from here, w/ all permutations
  }

  func testMajorFlow1() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmMinorDevice)))

    await store.send(.sadPathBtnTapped) {
      $0.screen = .onboarding(.major1_RENAME_ME)
    }

    // TODO: contine from here, with all the permutations..
    // consider a whole new file
  }

  func store(starting screen: IOSReducer.Screen) -> TestStore<IOSReducer.State, IOSReducer.Action> {
    TestStore(initialState: IOSReducer.State(screen: screen)) {
      IOSReducer()
    }
  }
}
