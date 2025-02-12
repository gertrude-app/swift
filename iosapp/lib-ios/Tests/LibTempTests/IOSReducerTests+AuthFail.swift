import ComposableArchitecture
import LibClients
import XCTest
import XExpect

@testable import LibTemp

final class IOSReducerTestsAuthFail: XCTestCase {
  func testInvalidAccountToSupervision() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = await TestStore(
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

    await store.send(.onlyBtnTapped)

    await store.receive(.authorizationFailed(.invalidAccountType)) {
      $0.screen = .onboarding(.authFail(.invalidAccount(.letsFigureThisOut)))
    }

    expect(apiLoggedDetails.value).toEqual(["authorization failed: invalidAccountType"])

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
    }

    await store.send(.primaryBtnTapped) { // <-- "yes, in an apple family"
      $0.screen = .onboarding(.authFail(.invalidAccount(.confirmIsMinor)))
    }

    await store.send(.primaryBtnTapped) { // <-- "Age is over 18"
      $0.screen = .onboarding(.major(.explainHarderButPossible))
    }
  }

  func testInvalidAccountUnder18Unexpected() async throws {
    let store = store(starting: .onboarding(.authFail(.invalidAccount(.confirmIsMinor))))

    await store.send(.secondaryBtnTapped) { // <-- "Age is UNDER 18"
      $0.screen = .onboarding(.authFail(.invalidAccount(.unexpected)))
    }
  }

  func testInvalidAccountNotInAppleFamily() async throws {
    let store = store(starting: .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))))

    await store.send(.secondaryBtnTapped) { // <-- "Not in Apple Family"
      $0.screen = .onboarding(.appleFamily(.explainRequiredForFiltering))
    }
  }

  func testInvalidAccountNotSureAboutAppleFamily() async throws {
    let store = store(starting: .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))))

    await store.send(.tertiaryBtnTapped) { // <-- "I'm not sure"
      $0.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
      $0.returningTo = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
    }

    await store.send(.primaryBtnTapped) { // <-- "Yes, in Apple Family"
      $0.screen = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
      $0.returningTo = nil
    }
  }

  func testAuthConflict() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = await TestStore(
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

    await store.send(.onlyBtnTapped)

    await store.receive(.authorizationFailed(.authorizationConflict)) {
      $0.screen = .onboarding(.authFail(.authConflict))
    }

    expect(apiLoggedDetails.value).toEqual(["authorization failed: authorizationConflict"])

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
    }
  }

  func testUnexpectedAuthFail() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = await TestStore(
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

    await store.send(.onlyBtnTapped)
    await store.receive(.authorizationFailed(.unexpected(.invalidArgument))) {
      $0.screen = .onboarding(.authFail(.unexpected))
    }
    expect(apiLoggedDetails.value).toEqual([
      "authorization failed: unexpected(LibClients.AuthFailureReason.Unexpected.invalidArgument)",
    ])
  }

  func testOtherAuthFail() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = await TestStore(
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

    await store.send(.onlyBtnTapped)
    await store.receive(.authorizationFailed(.other("printer on fire"))) {
      $0.screen = .onboarding(.authFail(.unexpected))
    }
    expect(apiLoggedDetails.value).toEqual([
      "authorization failed: other(\"printer on fire\")",
    ])
  }

  func testNetworkErrorAuthFail() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = await TestStore(
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

    await store.send(.onlyBtnTapped)
    await store.receive(.authorizationFailed(.networkError)) {
      $0.screen = .onboarding(.authFail(.networkError))
    }
    expect(apiLoggedDetails.value).toEqual(["authorization failed: networkError"])
    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
    }
  }

  func testPasscodeRequiredAuthFail() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = await TestStore(
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

    await store.send(.onlyBtnTapped)
    await store.receive(.authorizationFailed(.passcodeRequired)) {
      $0.screen = .onboarding(.authFail(.passcodeRequired))
    }
    expect(apiLoggedDetails.value).toEqual(["authorization failed: passcodeRequired"])
    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
    }
  }

  func testRestrictedAuthFail() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = await TestStore(
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

    await store.send(.onlyBtnTapped)
    await store.receive(.authorizationFailed(.restricted)) {
      $0.screen = .onboarding(.authFail(.restricted))
    }
    expect(apiLoggedDetails.value).toEqual(["authorization failed: restricted"])
  }

  func testCanceledAuthFail() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = await TestStore(
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

    await store.send(.onlyBtnTapped)
    await store.receive(.authorizationFailed(.authorizationCanceled)) {
      $0.screen = .onboarding(.authFail(.authCanceled))
    }
    expect(apiLoggedDetails.value).toEqual(["authorization failed: authorizationCanceled"])
    await store.send(.primaryBtnTapped) {
      $0.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
    }
  }
}
