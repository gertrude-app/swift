import ComposableArchitecture
import LibClients
import XCTest
import XExpect

@testable import LibApp

final class IOSReducerTestsFamily: XCTestCase {
  func testAppleFamilyFailFlow1() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmInAppleFamily)))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) { // <-- not in family
      $0.screen = .onboarding(.appleFamily(.explainRequiredForFiltering))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.appleFamily(.explainSetupFreeAndEasy))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.appleFamily(.howToSetupAppleFamily))
    }

    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) { // <-- "Done, continue"
      $0.screen = .onboarding(.happyPath(.confirmInAppleFamily))
    }
  }

  func testAppleFamilyDontKnowAtFirstButConfirmInOne() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmInAppleFamily)))

    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) { // <-- i'm not sure
      $0.screen = .onboarding(.appleFamily(.explainWhatIsAppleFamily))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
    }

    await store
      .send(.interactive(.onboardingBtnTapped(.primary, ""))) { // <-- "Yes, in Apple Family"
        $0.screen = .onboarding(.happyPath(.confirmInAppleFamily))
      }
  }

  func testAppleFamilyDontKnowAtFirstButConfirmNotInOne() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmInAppleFamily)))

    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) { // <-- i'm not sure
      $0.screen = .onboarding(.appleFamily(.explainWhatIsAppleFamily))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
    }

    await store
      .send(.interactive(.onboardingBtnTapped(.secondary, ""))) { // <-- "No, not in family"
        $0.screen = .onboarding(.appleFamily(.explainSetupFreeAndEasy))
      }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.appleFamily(.howToSetupAppleFamily))
    }

    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) { // <-- "Done, continue"
      $0.screen = .onboarding(.happyPath(.confirmInAppleFamily))
    }
  }
}
