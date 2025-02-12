import ComposableArchitecture
import LibClients
import XCTest
import XExpect

@testable import LibTemp

final class IOSReducerTestsFamily: XCTestCase {
  func testAppleFamilyFailFlow1() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmInAppleFamily)))

    await store.send(.sadPathBtnTapped) {
      $0.screen = .onboarding(.appleFamily(.explainRequiredForFiltering))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.appleFamily(.explainSetupFreeAndEasy))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.appleFamily(.howToSetupAppleFamily))
    }

    await store.send(.tertiaryBtnTapped) { // <-- "Done, continue"
      $0.screen = .onboarding(.happyPath(.confirmInAppleFamily))
    }
  }

  func testAppleFamilyDontKnowAtFirstButConfirmInOne() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmInAppleFamily)))

    await store.send(.iDontKnowBtnTapped) {
      $0.screen = .onboarding(.appleFamily(.explainWhatIsAppleFamily))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
    }

    await store.send(.primaryBtnTapped) { // <-- "Yes, in Apple Family"
      $0.screen = .onboarding(.happyPath(.confirmInAppleFamily))
    }
  }

  func testAppleFamilyDontKnowAtFirstButConfirmNotInOne() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmInAppleFamily)))

    await store.send(.iDontKnowBtnTapped) {
      $0.screen = .onboarding(.appleFamily(.explainWhatIsAppleFamily))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
    }

    await store.send(.secondaryBtnTapped) { // <-- "No, not in family"
      $0.screen = .onboarding(.appleFamily(.explainSetupFreeAndEasy))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.appleFamily(.howToSetupAppleFamily))
    }

    await store.send(.tertiaryBtnTapped) { // <-- "Done, continue"
      $0.screen = .onboarding(.happyPath(.confirmInAppleFamily))
    }
  }
}
