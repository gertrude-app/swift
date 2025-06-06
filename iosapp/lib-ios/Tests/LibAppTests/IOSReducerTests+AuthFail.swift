import ComposableArchitecture
import LibClients
import XCTest
import XExpect

@testable import LibApp

final class IOSReducerTestsAuthFail: XCTestCase {
  @MainActor
  func testInvalidAccountToSupervision() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.dontGetTrickedPreAuth)))
    ) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _id, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.systemExtension.requestAuthorization = {
        .failure(.invalidAccountType)
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store.receive(.programmatic(.authorizationFailed(.invalidAccountType))) {
      $0.screen = .onboarding(.authFail(.invalidAccount(.letsFigureThisOut)))
    }

    expect(apiLoggedDetails.value)
      .toEqual(["[onboarding] authorization failed: invalidAccountType"])

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
    }

    await store
      .send(.interactive(.onboardingBtnTapped(.primary, ""))) { // <-- "yes, in an apple family"
        $0.screen = .onboarding(.authFail(.invalidAccount(.confirmIsMinor)))
      }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) { // <-- "Age is over 18"
      $0.screen = .onboarding(.major(.explainHarderButPossible))
    }
  }

  @MainActor
  func testInvalidAccountUnder18Unexpected() async throws {
    let store = store(starting: .onboarding(.authFail(.invalidAccount(.confirmIsMinor))))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) { // <-- "Age is UNDER 18"
      $0.screen = .onboarding(.authFail(.invalidAccount(.unexpected)))
    }
  }

  @MainActor
  func testInvalidAccountNotInAppleFamily() async throws {
    let store = store(starting: .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))))

    await store
      .send(.interactive(.onboardingBtnTapped(.secondary, ""))) { // <-- "Not in Apple Family"
        $0.screen = .onboarding(.appleFamily(.explainRequiredForFiltering))
      }
  }

  @MainActor
  func testInvalidAccountNotSureAboutAppleFamily() async throws {
    let store = store(starting: .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))))

    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) { // <-- "I'm not sure"
      $0.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
      $0.onboarding.returningTo = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
    }

    await store
      .send(.interactive(.onboardingBtnTapped(.primary, ""))) { // <-- "Yes, in Apple Family"
        $0.screen = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
        $0.onboarding.returningTo = nil
      }
  }

  @MainActor
  func testInvalidAccountNotSureAboutAppleFamilyConfirmsNotInOne() async throws {
    let store = store(starting: .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))))

    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) { // <-- "I'm not sure"
      $0.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
      $0.onboarding.returningTo = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
    }

    await store
      .send(.interactive(.onboardingBtnTapped(.secondary, ""))) { // <-- "No, not in a family"
        $0.screen = .onboarding(.appleFamily(.explainSetupFreeAndEasy))
      }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.appleFamily(.howToSetupAppleFamily))
    }

    await store
      .send(.interactive(.onboardingBtnTapped(.tertiary, ""))) { // <-- "Done, now in a family"
        $0.screen = .onboarding(.happyPath(.confirmInAppleFamily))
        $0.onboarding.returningTo = nil
      }
  }

  @MainActor
  func testAuthConflict() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.dontGetTrickedPreAuth)))
    ) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _id, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.systemExtension.requestAuthorization = {
        .failure(.authorizationConflict)
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store.receive(.programmatic(.authorizationFailed(.authorizationConflict))) {
      $0.screen = .onboarding(.authFail(.authConflict))
    }

    expect(apiLoggedDetails.value)
      .toEqual(["[onboarding] authorization failed: authorizationConflict"])

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
    }
  }

  @MainActor
  func testUnexpectedAuthFail() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.dontGetTrickedPreAuth)))
    ) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _id, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.systemExtension.requestAuthorization = {
        .failure(.unexpected(.invalidArgument))
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    await store.receive(.programmatic(.authorizationFailed(.unexpected(.invalidArgument)))) {
      $0.screen = .onboarding(.authFail(.unexpected))
    }
    expect(apiLoggedDetails.value).toEqual([
      "[onboarding] authorization failed: unexpected(LibClients.AuthFailureReason.Unexpected.invalidArgument)",
    ])

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
    }
  }

  @MainActor
  func testOtherAuthFail() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.dontGetTrickedPreAuth)))
    ) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _id, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.systemExtension.requestAuthorization = {
        .failure(.other("printer on fire"))
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    await store.receive(.programmatic(.authorizationFailed(.other("printer on fire")))) {
      $0.screen = .onboarding(.authFail(.unexpected))
    }
    expect(apiLoggedDetails.value).toEqual([
      "[onboarding] authorization failed: other(\"printer on fire\")",
    ])
  }

  @MainActor
  func testNetworkErrorAuthFail() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.dontGetTrickedPreAuth)))
    ) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _id, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.systemExtension.requestAuthorization = {
        .failure(.networkError)
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    await store.receive(.programmatic(.authorizationFailed(.networkError))) {
      $0.screen = .onboarding(.authFail(.networkError))
    }
    expect(apiLoggedDetails.value).toEqual(["[onboarding] authorization failed: networkError"])
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
    }
  }

  @MainActor
  func testPasscodeRequiredAuthFail() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.dontGetTrickedPreAuth)))
    ) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _id, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.systemExtension.requestAuthorization = {
        .failure(.passcodeRequired)
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    await store.receive(.programmatic(.authorizationFailed(.passcodeRequired))) {
      $0.screen = .onboarding(.authFail(.passcodeRequired))
    }
    expect(apiLoggedDetails.value)
      .toEqual(["[onboarding] authorization failed: passcodeRequired"])
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
    }
  }

  @MainActor
  func testRestrictedAuthFail() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.dontGetTrickedPreAuth)))
    ) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _id, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.systemExtension.requestAuthorization = {
        .failure(.restricted)
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    await store.receive(.programmatic(.authorizationFailed(.restricted))) {
      $0.screen = .onboarding(.authFail(.restricted))
    }
    expect(apiLoggedDetails.value)
      .toEqual(["[onboarding] authorization failed: restricted"])
  }

  @MainActor
  func testCanceledAuthFail() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.dontGetTrickedPreAuth)))
    ) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _id, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.systemExtension.requestAuthorization = {
        .failure(.authorizationCanceled)
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))
    await store.receive(.programmatic(.authorizationFailed(.authorizationCanceled))) {
      $0.screen = .onboarding(.authFail(.authCanceled))
    }
    expect(apiLoggedDetails.value)
      .toEqual(["[onboarding] authorization failed: authorizationCanceled"])
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
    }
  }
}
