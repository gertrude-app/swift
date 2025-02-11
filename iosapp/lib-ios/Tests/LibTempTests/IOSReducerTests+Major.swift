import ComposableArchitecture
import LibClients
import XCTest
import XExpect

@testable import LibTemp

final class IOSReducerTestsMajor: XCTestCase {
  func testMajorHappiestPath() async throws {
    let store = store(starting: .onboarding(.happyPath(.confirmMinorDevice)))

    await store.send(.sadPathBtnTapped) {
      $0.screen = .onboarding(.major(.explainHarderButPossible))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.major(.askSelfOrOtherIsOnboarding))
    }

    await store.send(.secondaryBtnTapped) {
      $0.screen = .onboarding(.major(.askIfOtherIsParent))
      $0.majorOnboarder = .other
    }

    await store.send(.primaryBtnTapped) {
      $0.screen = .onboarding(.major(.explainFixAccountTypeEasyWay))
    }

    await store.send(.primaryBtnTapped) {
      $0.screen = .onboarding(.happyPath(.confirmMinorDevice))
    }
  }

  func testMajorSelfPath1() async throws {
    let store = store(starting: .onboarding(.major(.askSelfOrOtherIsOnboarding)))

    await store.send(.tertiaryBtnTapped) {
      $0.majorOnboarder = .self
      $0.screen = .onboarding(.major(.askIfInAppleFamily))
    }

    // first they click "what's an apple family" and see the sheet
    await store.send(.tertiaryBtnTapped) {
      $0.screen = .onboarding(.major(.explainAppleFamily))
    }

    // dismiss the sheet
    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.major(.askIfInAppleFamily))
    }

    // now they click that they could be in an apple family
    await store.send(.primaryBtnTapped) {
      $0.screen = .onboarding(.major(.explainFixAccountTypeEasyWay))
    }

    // they click "is there another way?" from easy fix account screen
    await store.send(.secondaryBtnTapped) {
      $0.screen = .onboarding(.major(.askIfOwnsMac))
    }

    await store.send(.primaryBtnTapped) {
      $0.screen = .onboarding(.supervision(.intro))
      $0.ownsMac = true
    }
  }

  func testMajorSelfNoAppleFamilyStraightToSupervision() async throws {
    let store = store(starting: .onboarding(.major(.askSelfOrOtherIsOnboarding)))

    await store.send(.tertiaryBtnTapped) {
      $0.majorOnboarder = .self
      $0.screen = .onboarding(.major(.askIfInAppleFamily))
    }

    await store.send(.secondaryBtnTapped) {
      $0.screen = .onboarding(.supervision(.intro))
    }
  }

  func testMajorNoMacSetsState() async throws {
    let store = store(starting: .onboarding(.major(.askIfOwnsMac)))

    await store.send(.secondaryBtnTapped) {
      $0.screen = .onboarding(.supervision(.intro))
      $0.ownsMac = false
    }
  }

  func testSupervisionHappiestPath() async throws {
    let store = await TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.intro)),
      majorOnboarder: .other,
      ownsMac: true
    )) {
      IOSReducer()
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.supervision(.explainSupervision))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.supervision(.explainRequiresEraseAndSetup))
    }

    await store.send(.primaryBtnTapped) {
      $0.screen = .onboarding(.supervision(.instructions))
    }
  }

  func testSupervisionNeedsFriendHasFriendPath() async throws {
    let store = await TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.intro)),
      majorOnboarder: .self,
      ownsMac: true
    )) {
      IOSReducer()
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.supervision(.explainSupervision))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.supervision(.explainNeedFriendWithMac))
    }

    await store.send(.primaryBtnTapped) { // <-- "i have a friend"
      $0.screen = .onboarding(.supervision(.explainRequiresEraseAndSetup))
    }

    await store.send(.secondaryBtnTapped) {
      $0.screen = .onboarding(.supervision(.sorryNoOtherWay))
    }
  }

  func testSupervisionNeedsFriendNoFriendPath() async throws {
    let store = await TestStore(initialState: IOSReducer.State(
      screen: .onboarding(.supervision(.intro)),
      majorOnboarder: .self,
      ownsMac: false
    )) {
      IOSReducer()
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.supervision(.explainSupervision))
    }

    await store.send(.onlyBtnTapped) {
      $0.screen = .onboarding(.supervision(.explainNeedFriendWithMac))
    }

    await store.send(.secondaryBtnTapped) { // <-- "don't have a friend"
      $0.screen = .onboarding(.supervision(.sorryNoOtherWay))
    }
  }
}
