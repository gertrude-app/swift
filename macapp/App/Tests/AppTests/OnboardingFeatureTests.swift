import Combine
import ComposableArchitecture
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

@MainActor final class OnboardingFeatureTests: XCTestCase {
  func testFirstBootOnboardingHappyPathExhaustive() async {
    let (store, _) = AppReducer.testStore(exhaustive: true, mockDeps: false)
    store.deps.mainQueue = .immediate

    // TODO: this is a little weird that i have to mock these, seems like
    // maybe some listeners shouldn't initialize until we start the heartbeat? or something?
    store.deps.filterExtension.stateChanges = { Empty().eraseToAnyPublisher() }
    store.deps.filterXpc.events = { Empty().eraseToAnyPublisher() }
    store.deps.websocket.receive = { Empty().eraseToAnyPublisher() }
    store.deps.websocket.state = { .notConnected }

    store.deps.device.currentUserId = { 502 }
    store.deps.device.listMacOSUsers = DeviceClient.mock.listMacOSUsers

    store.deps.storage.loadPersistentState = { nil } // <-- first boot
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    store.deps.filterExtension.setup = { .notInstalled }

    await store.send(.application(.didFinishLaunching))

    await store.receive(.filter(.receivedState(.notInstalled))) {
      $0.filter.extension = .notInstalled
    }

    await store.receive(.loadedPersistentState(nil)) {
      $0.onboarding.windowOpen = true
      $0.onboarding.step = .welcome
    }

    await expect(saveState.invocations.value).toHaveCount(1)

    // they click next on the welcome screen...
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .confirmGertrudeAccount // ... and go to confirm account
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

    // next they confirm that they have a gertrude account...
    store.deps.device.currentMacOsUserType = { .standard }
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .macosUserAccountType // ...and end up on the macos user screen
    }

    // they click next on the macos user confirmation good page...
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .getChildConnectionCode // ...and go to the get connection screen
    }

    // they click the "got it" button on get connection code screen...
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .connectChild // ... and end up on the connect child screen
      $0.onboarding.connectChildRequest = .idle
    }

    let user = UserData.mock { $0.name = "lil suzy" }
    let connectUser = spy(on: ConnectUser.Input.self, returning: user)
    store.deps.api.connectUser = connectUser.fn
    store.deps.app.installedVersion = { "1.0.0" }
    await expect(saveState.invocations.value).toHaveCount(1)
    store.deps.device = .mock // lots of data used by connect user request

    // they enter code `123456` and click submit...
    await store.send(.onboarding(.webview(.connectChildSubmitted(123_456)))) {
      $0.onboarding.step = .connectChild
      $0.onboarding.connectChildRequest = .ongoing // ... and see a throbber
    }

    await expect(connectUser.invocations.value).toHaveCount(1)
    await expect(connectUser.invocations.value[0].verificationCode).toEqual(123_456)

    await store.receive(.onboarding(.connectUser(.success(user)))) {
      $0.user.data = user
      $0.onboarding.step = .connectChild
      $0.onboarding.connectChildRequest = .succeeded(payload: "lil suzy")
    }

    // we persisted the user data
    await expect(saveState.invocations.value).toHaveCount(2)
    await expect(saveState.invocations.value[1].user).toEqual(user)

    // they click "next" on the connected child success screen...
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .allowNotifications_start // ...and go to notifications screen
    }

    // 👍 Tuesday jared
    // next test allow notifications happy path...
    //   ...plus: then skipping notification step
    //   ...plus: edge case (already granted permissions)

    await store.send(.application(.willTerminate))
  }

  func testConnectChildFailure() async {
    let (store, _) = AppReducer.testStore {
      $0.onboarding.step = .connectChild
      $0.onboarding.connectChildRequest = .ongoing
    }
    let openWebUrl = spy(on: URL.self, returning: ())
    store.deps.device.openWebUrl = openWebUrl.fn

    await store.send(.onboarding(.connectUser(.failure(TestErr("oh noes!"))))) {
      $0.onboarding.step = .connectChild
      $0.onboarding.connectChildRequest = .failed(
        error: "Sorry, something went wrong. Please try again, or contact help if the problem persists."
      )
    }

    // they clicked the "get help" button
    await store.send(.onboarding(.webview(.secondaryBtnClicked)))
    await expect(openWebUrl.invocations).toEqual([.init(string: "https://gertrude.app/contact")!])

    // they clicked "try again"
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .getChildConnectionCode
      $0.onboarding.connectChildRequest = .idle
    }
  }

  func testResumingAtMacOSUserType() async {
    let (store, _) = AppReducer.testStore()
    store.deps.storage.loadPersistentState = { .init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .stable,
      filterVersion: "1.0.0",
      user: nil,
      onboardingStep: .macosUserAccountType
    ) }
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    await store.send(.application(.didFinishLaunching))
    await store.skipReceivedActions()
    store.assert {
      $0.onboarding.windowOpen = true
      $0.onboarding.step = .macosUserAccountType
    }

    await expect(saveState.invocations).toEqual([
      .init(
        appVersion: "1.0.0",
        appUpdateReleaseChannel: .stable,
        filterVersion: "1.0.0",
        user: nil,
        onboardingStep: nil // <-- nils out step
      ),
    ])
  }

  func testNoGertrudeAccountQuit() async {
    let store = featureStore()
    store.deps.device = .mock
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
