import ComposableArchitecture
import LibClients
import XCTest
import XExpect

@testable import LibTemp

final class IOSReducerTestsInstallFail: XCTestCase {
  func testInstallErrPermissionDeniedFlow() async throws {
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
        .failure(.configurationPermissionDenied)
      }
    }

    await store.send(.onlyBtnTapped)

    await store.receive(.installFailed(.configurationPermissionDenied)) {
      $0.screen = .onboarding(.installFail(.permissionDenied))
    }
    expect(apiLoggedDetails.value).toEqual(["filter install failed: configurationPermissionDenied"])

    await store.send(.primaryBtnTapped) { // <-- "try again"
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

    await store.send(.onlyBtnTapped)

    await store.receive(.installFailed(.configurationInternalError)) {
      $0.screen = .onboarding(.installFail(.other(.configurationInternalError)))
    }
    expect(apiLoggedDetails.value).toEqual(["filter install failed: configurationInternalError"])

    await store.send(.primaryBtnTapped) { // <-- "try again"
      $0.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    }
  }
}
