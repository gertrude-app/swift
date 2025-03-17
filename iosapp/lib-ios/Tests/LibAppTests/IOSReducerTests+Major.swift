import ComposableArchitecture
import LibClients
import XCTest
import XExpect

@testable import LibApp

final class IOSReducerTestsMajor: XCTestCase {
  @MainActor
  func testMajorHappiestPath() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmMinorDevice)))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) { // <-- over 18
      $0.screen = .onboarding(.major(.explainHarderButPossible))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.major(.askSelfOrOtherIsOnboarding))
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.major(.askIfOtherIsParent))
      $0.onboarding.majorOnboarder = .other
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.major(.explainFixAccountTypeEasyWay))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.happyPath(.confirmMinorDevice))
    }
  }

  @MainActor
  func testMajorSelfPath1() async throws {
    let store = store(starting: .onboarding(.major(.askSelfOrOtherIsOnboarding)))

    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.onboarding.majorOnboarder = .self
      $0.screen = .onboarding(.major(.askIfInAppleFamily))
    }

    // first they click "what's an apple family" and see the sheet
    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.screen = .onboarding(.major(.explainAppleFamily))
    }

    // dismiss the sheet (by button)
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.major(.askIfInAppleFamily))
    }

    // show the sheet again, so we can test the dismiss action
    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.screen = .onboarding(.major(.explainAppleFamily))
    }

    // dismiss the sheet (by dismiss gesture)
    await store.send(.interactive(.sheetDismissed)) {
      $0.screen = .onboarding(.major(.askIfInAppleFamily))
    }

    // now they click that they could be in an apple family
    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.major(.explainFixAccountTypeEasyWay))
    }

    // they click "is there another way?" from easy fix account screen
    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.major(.askIfOwnsMac))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.intro))
      $0.onboarding.ownsMac = true
    }
  }

  @MainActor
  func testMajorSelfNoAppleFamilyStraightToSupervision() async throws {
    let store = store(starting: .onboarding(.major(.askSelfOrOtherIsOnboarding)))

    await store.send(.interactive(.onboardingBtnTapped(.tertiary, ""))) {
      $0.onboarding.majorOnboarder = .self
      $0.screen = .onboarding(.major(.askIfInAppleFamily))
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.supervision(.intro))
    }
  }

  @MainActor
  func testMajorNoMacSetsState() async throws {
    let store = store(starting: .onboarding(.major(.askIfOwnsMac)))

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.supervision(.intro))
      $0.onboarding.ownsMac = false
    }
  }

  func testSupervisionHappiestPath() async throws {
    let store = await TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.intro)),
      onboarding: .init(majorOnboarder: .other, ownsMac: true)
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.explainSupervision))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.explainRequiresEraseAndSetup))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.instructions))
    }
  }

  func testSupervisionNeedsFriendHasFriendPath() async throws {
    let store = await TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.intro)),
      onboarding: .init(majorOnboarder: .self, ownsMac: true)
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.explainSupervision))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.explainNeedFriendWithMac))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) { // <-- "i have a friend"
      $0.screen = .onboarding(.supervision(.explainRequiresEraseAndSetup))
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.supervision(.sorryNoOtherWay))
    }
  }

  func testSupervisionNeedsFriendNoFriendPath() async throws {
    let store = await TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.intro)),
      onboarding: .init(majorOnboarder: .self, ownsMac: false)
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.explainSupervision))
    }

    await store.send(.interactive(.onboardingBtnTapped(.primary, ""))) {
      $0.screen = .onboarding(.supervision(.explainNeedFriendWithMac))
    }

    await store
      .send(.interactive(.onboardingBtnTapped(.secondary, ""))) { // <-- "don't have a friend"
        $0.screen = .onboarding(.supervision(.sorryNoOtherWay))
      }
  }

  func testSupervisionOtherNotParentOrGuardian() async throws {
    let store = await TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.major(.askIfOtherIsParent)),
      onboarding: .init(majorOnboarder: .other, ownsMac: nil)
    )) {
      IOSReducer()
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.major(.askIfOwnsMac))
    }

    await store.send(.interactive(.onboardingBtnTapped(.secondary, ""))) {
      $0.screen = .onboarding(.supervision(.intro))
      $0.onboarding.ownsMac = false
    }
  }
}
