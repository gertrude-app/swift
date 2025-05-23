import ComposableArchitecture
import LibClients
import XCTest
import XExpect

@testable import LibApp

final class IOSReducerTestsInstallFail: XCTestCase {
  func testInstallErrPermissionDeniedFlow() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let cleanupContentFilterInvocations = LockIsolated(0)
    let cleanupScreenTimeInvocations = LockIsolated(0)
    let store = await TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.dontGetTrickedPreInstall)))
    ) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _id, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.systemExtension.installFilter = {
        .failure(.configurationPermissionDenied)
      }
      $0.systemExtension.cleanupContentFilterForRetry = {
        cleanupContentFilterInvocations.withValue { $0 += 1 }
      }
      $0.systemExtension.cleanupScreenTimeAuthForRetry = {
        cleanupScreenTimeInvocations.withValue { $0 += 1 }
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store.receive(.programmatic(.installFailed(.configurationPermissionDenied))) {
      $0.screen = .onboarding(.installFail(.permissionDenied))
    }

    expect(apiLoggedDetails.value)
      .toEqual(["[onboarding] filter install failed: configurationPermissionDenied"])
    expect(cleanupContentFilterInvocations.value).toEqual(1)

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) { // <-- "try again"
      $0.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    }
  }

  func testInstallOtherError() async throws {
    let apiLoggedDetails = LockIsolated<[String]>([])
    let store = await TestStore(
      initialState: IOSReducer.State(screen: .onboarding(.happyPath(.dontGetTrickedPreInstall)))
    ) {
      IOSReducer()
    } withDependencies: {
      $0.api.logEvent = { @Sendable _id, detail in
        apiLoggedDetails.withValue { $0.append(detail ?? "") }
      }
      $0.systemExtension.installFilter = {
        .failure(.configurationInternalError)
      }
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, "")))

    await store.receive(.programmatic(.installFailed(.configurationInternalError))) {
      $0.screen = .onboarding(.installFail(.other(.configurationInternalError)))
    }
    expect(apiLoggedDetails.value)
      .toEqual(["[onboarding] filter install failed: configurationInternalError"])

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) { // <-- "try again"
      $0.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    }
  }
}
