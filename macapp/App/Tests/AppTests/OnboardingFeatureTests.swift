import ComposableArchitecture
import TestSupport
import XCTest
import XExpect

@testable import App

@MainActor final class OnboardingFeatureTests: XCTestCase {
  func testFirstBootOnboardingHappyPathExhaustive() async {
    let (store, _) = AppReducer.testStore(exhaustive: true, mockDeps: false)
    store.deps.mainQueue = .immediate

    store.deps.storage.loadPersistentState = { nil } // <-- first boot
    store.deps.filterExtension.setup = { .notInstalled }

    await store.send(.application(.didFinishLaunching))

    await store.receive(.filter(.receivedState(.notInstalled))) {
      $0.filter.extension = .notInstalled
    }

    await store.receive(.loadedPersistentState(nil)) {
      $0.onboarding.windowOpen = true
      $0.onboarding.step = .welcome
    }

    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .confirmGertrudeAccount
    }

    await store.receive(.onboarding(.receivedUserData(502, [
      .init(id: 501, name: "Dad", type: .admin),
      .init(id: 502, name: "liljimmy", type: .standard),
    ]))) {
      $0.onboarding.users = [
        .init(id: 501, name: "Dad", isAdmin: true),
        .init(id: 502, name: "liljimmy", isAdmin: false),
      ]
      $0.onboarding.currentUser = .init(id: 502, name: "liljimmy", isAdmin: false)
    }

    store.deps.device.currentMacOsUserType = { .standard }
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .macosUserAccountType
    }

    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .getChildConnectionCode
    }

    await store.send(.application(.willTerminate))
  }

  // TODO: test luanching app and resuming from a step, incl. that it nils out step

  func testNoGertrudeAccountQuit() async {
    let store = featureStore()
    let quit = mock(once: ())
    store.deps.app.quit = quit.fn
    let deleteAll = mock(once: ())
    store.deps.storage.deleteAll = deleteAll.fn

    await store.send(.webview(.primaryBtnClicked))

    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .noGertrudeAccount
    }

    await store.send(.webview(.secondaryBtnClicked))
    await expect(deleteAll.invoked).toEqual(true)
    await expect(quit.invoked).toEqual(true)
  }

  func testBadUserTypeIgnoresDanger() async {
    let store = featureStore()
    store.deps.device.currentUserId = { 501 }
    store.deps.device.listMacOSUsers = { [.init(id: 501, name: "Dad", type: .admin)] }

    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .confirmGertrudeAccount
    }

    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .macosUserAccountType
      $0.userRemediationStep = nil
    }

    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .getChildConnectionCode
    }
  }

  func testBadUserTypeNoChoice() async {
    let store = featureStore()
    store.deps.device.currentUserId = { 501 }
    store.deps.device.listMacOSUsers = { [.init(id: 501, name: "Dad", type: .admin)] }

    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .confirmGertrudeAccount
    }

    // they click confirming they have a gertrude acct...
    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .macosUserAccountType // ...landing them on user type warning page
      $0.userRemediationStep = nil
    }

    // they click the primary btn: show me how to fix it...
    await store.send(.webview(.primaryBtnClicked)) {
      // because they only have ONE admin user on the system,
      // we take them straight to step to create a new user
      $0.userRemediationStep = .create
    }
  }

  func testBadUserTypeWithChoice() async {
    let store = featureStore()

    store.deps.device.currentUserId = { 501 }
    store.deps.device.listMacOSUsers = { [
      .init(id: 501, name: "Dad", type: .admin),
      .init(id: 503, name: "Mom", type: .admin),
      .init(id: 502, name: "liljimmy", type: .standard),
    ] }

    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .confirmGertrudeAccount
    }

    // they click confirming they have a gertrude acct...
    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .macosUserAccountType // ...landing them on user type warning page
      $0.userRemediationStep = nil
    }

    // they click the primary btn: show me how to fix it...
    await store.send(.webview(.primaryBtnClicked)) {
      // because they have options for remediation, they must choose
      $0.userRemediationStep = .choose
    }

    // remediations require restarting gertrude, so note the step to restart w/
    await store.receive(.delegate(.saveCurrentStep(.macosUserAccountType)))

    await store.send(.webview(.chooseDemoteAdminClicked)) {
      $0.userRemediationStep = .demote
    }
  }

  // helpers

  func featureStore() -> TestStoreOf<OnboardingFeature.Reducer> {
    let store = TestStore(initialState: OnboardingFeature.State()) {
      OnboardingFeature.Reducer()
    }
    store.exhaustivity = .off
    return store
  }
}
