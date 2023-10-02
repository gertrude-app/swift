import Combine
import ComposableArchitecture
import Core
import Gertie
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

@MainActor final class OnboardingFeatureTests: XCTestCase {
  func testFirstBootOnboardingHappyPathExhaustive() async {
    let (store, _) = AppReducer.testStore(exhaustive: true, mockDeps: false)
    let scheduler = DispatchQueue.test
    store.deps.backgroundQueue = scheduler.eraseToAnyScheduler()
    store.deps.mainQueue = .immediate
    store.deps.filterExtension.stateChanges = { Empty().eraseToAnyPublisher() }
    store.deps.filterXpc.events = { Empty().eraseToAnyPublisher() }
    store.deps.websocket.state = { .notConnected }

    store.deps.device.currentUserId = { 502 }
    store.deps.device.listMacOSUsers = DeviceClient.mock.listMacOSUsers
    store.deps.device.notificationsSetting = { .none }

    store.deps.storage.loadPersistentState = { nil } // <-- first boot
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    let extSetup = mock(always: FilterExtensionState.notInstalled)
    store.deps.filterExtension.setup = extSetup.fn

    await store.send(.application(.didFinishLaunching))

    await store.receive(.loadedPersistentState(nil)) {
      $0.onboarding.windowOpen = true
      $0.onboarding.step = .welcome
    }

    await store.receive(.filter(.receivedState(.notInstalled))) {
      $0.filter.extension = .notInstalled
    }

    await expect(extSetup.invocations).toEqual(1)
    await expect(saveState.invocations.value).toHaveCount(1)

    // they click next on the welcome screen...
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .confirmGertrudeAccount // ... and go to confirm account
    }

    await store.receive(.onboarding(.receivedDeviceData(
      currentUserId: 502,
      users: [
        .init(id: 501, name: "Dad", type: .admin),
        .init(id: 502, name: "liljimmy", type: .standard),
      ],
      notificationsSetting: .none
    ))) {
      $0.onboarding.users = [
        .init(id: 501, name: "Dad", isAdmin: true),
        .init(id: 502, name: "liljimmy", isAdmin: false),
      ]
      $0.onboarding.currentUser = .init(id: 502, name: "liljimmy", isAdmin: false)
      $0.onboarding.existingNotificationsSetting = .some(.none)
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

    // lots happens when the user connection is made...
    let user = UserData.mock { $0.name = "lil suzy" }
    let connectUser = spy(on: ConnectUser.Input.self, returning: user)
    store.deps.api.connectUser = connectUser.fn
    let setUserToken = spy(on: UUID.self, returning: ())
    store.deps.api.setUserToken = setUserToken.fn
    let setAccountActive = spy(on: Bool.self, returning: ())
    store.deps.api.setAccountActive = setAccountActive.fn
    let checkInResult = CheckIn.Output.empty { $0.userData = user }
    let checkIn = spy(on: CheckIn.Input.self, returning: checkInResult)
    store.deps.api.checkIn = checkIn.fn
    store.deps.app.installedVersion = { "1.0.0" }
    await expect(saveState.invocations.value).toHaveCount(1)
    store.deps.device = .mock // lots of data used by connect user request
    store.deps.websocket.receive = { Empty().eraseToAnyPublisher() }

    // they enter code `123456` and click submit...
    await store.send(.onboarding(.webview(.connectChildSubmitted(123_456)))) {
      $0.onboarding.step = .connectChild
      $0.onboarding.connectChildRequest = .ongoing // ... and see a throbber
    }

    await expect(connectUser.invocations.value).toHaveCount(1)
    await expect(connectUser.invocations.value[0].verificationCode).toEqual(123_456)
    await expect(setUserToken.invocations).toEqual([UserData.mock.token])
    await expect(setAccountActive.invocations).toEqual([true])
    await expect(checkIn.invocations).toEqual([.init(appVersion: "1.0.0", filterVersion: "1.0.0")])

    await store.receive(.onboarding(.connectUser(.success(user)))) {
      $0.user.data = user
      $0.onboarding.step = .connectChild
      $0.onboarding.connectChildRequest = .succeeded(payload: "lil suzy")
    }

    await store.receive(.startProtecting(user: user, from: .onboardingConnection))
    await store.receive(.checkIn(result: .success(checkInResult), reason: .userConnected)) {
      $0.appUpdates.latestVersion = checkInResult.latestRelease
    }
    await store.receive(.user(.updated(previous: user)))

    // we persisted the user data
    await expect(saveState.invocations.value).toHaveCount(3)
    await expect(saveState.invocations.value[1].user).toEqual(user)

    // they click "next" on the connected child success screen...
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .allowNotifications_start // ...and go to notifications screen
    }

    let requestNotifAuth = mock(always: ())
    store.deps.device.requestNotificationAuthorization = requestNotifAuth.fn
    let openSysPrefs = spy(on: SystemPrefsLocation.self, returning: ())
    store.deps.device.openSystemPrefs = openSysPrefs.fn

    // they click "Open System Settings" on the notifications start screen
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .allowNotifications_grant // ...and go to grant
    }

    // ... and we requested authorization and then opened system prefs
    await expect(requestNotifAuth.invocations).toEqual(1)
    await expect(openSysPrefs.invocations).toEqual([.notifications])

    // they did indeed enable notifications...
    let notifsSettings = mock(always: NotificationsSetting.alert)
    store.deps.device.notificationsSetting = notifsSettings.fn
    // ... and then clicked "Done" on the notifications grant screen
    await store.send(.onboarding(.webview(.primaryBtnClicked)))

    // ...and we confirmed the setting and moved them on the happy path
    await expect(notifsSettings.invocations).toEqual(1)
    await store.receive(.onboarding(.setStep(.allowScreenshots_required))) {
      $0.onboarding.step = .allowScreenshots_required
    }

    // they have not previously granted permission...
    let screenshotsAllowed = mock(returning: [false], then: true)
    store.deps.monitoring.screenRecordingPermissionGranted = screenshotsAllowed.fn

    // they click "Grant Permission" on the allow screenshots start screen
    await store.send(.onboarding(.webview(.primaryBtnClicked)))

    // ...and we check the setting (which pops up prompt) and moved them on
    await expect(screenshotsAllowed.invocations).toEqual(1)
    await store.receive(.onboarding(.setStep(.allowScreenshots_openSysSettings))) {
      $0.onboarding.step = .allowScreenshots_openSysSettings // ...and go to open
    }

    // they click "Done" indicating that they clicked the system prompt
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .allowScreenshots_grantAndRestart // ...and go to grant
    }

    // NB: here technically they RESTART the app, but instead of starting a new test
    // we simulate receiving the resume action to carry on where they should
    // we have other tests testing the resume from persisted state flow.
    await store.send(.onboarding(.resume(.checkingScreenRecordingPermission)))

    await store.receive(.onboarding(.setStep(.allowScreenshots_success))) {
      $0.onboarding.step = .allowScreenshots_success
    }

    // they click the "Next" button from the screen recording success
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .allowKeylogging_required // ...and go to keylogging
    }

    // they have not previously granted permission...
    let keyloggingAllowed = mock(returning: [false], then: true)
    store.deps.monitoring.keystrokeRecordingPermissionGranted = keyloggingAllowed.fn

    // they click "Grant Permission" on the allow keylogging start screen
    await store.send(.onboarding(.webview(.primaryBtnClicked)))

    // ...and we check the setting (which pops up prompt) and moved them on
    await expect(keyloggingAllowed.invocations).toEqual(1)
    await store.receive(.onboarding(.setStep(.allowKeylogging_openSysSettings))) {
      $0.onboarding.step = .allowKeylogging_openSysSettings // ...and go to open
    }

    // they click "Done" indicating that they clicked the system prompt
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .allowKeylogging_grant // ...and go to grant
    }

    // they click "Done" indicating they think they've allowed keylogging
    await store.send(.onboarding(.webview(.primaryBtnClicked)))

    // we confirm, and see that the did it correct...
    await expect(keyloggingAllowed.invocations).toEqual(2)
    // ...so they get sent off to the next happy path step
    await store.receive(.onboarding(.setStep(.installSysExt_explain))) {
      $0.onboarding.step = .installSysExt_explain // ...and go to sys ext start
    }

    let filterState = mock(returning: [FilterExtensionState.notInstalled, .installedAndRunning])
    store.deps.filterExtension.state = filterState.fn
    let installSysExt = mock(once: FilterInstallResult.installedSuccessfully)
    store.deps.filterExtension.install = installSysExt.fn

    // they click "Next" on the install sys ext start screen
    await store.send(.onboarding(.webview(.primaryBtnClicked)))
    await expect(installSysExt.invocations).toEqual(1)
    await store.receive(.onboarding(.setStep(.installSysExt_allow))) {
      $0.onboarding.step = .installSysExt_allow // ...and go to sys ext allow
    }

    // becuase filterExtension.install is mocked to return success, we go to success
    await store.receive(.onboarding(.setStep(.installSysExt_success))) {
      $0.onboarding.step = .installSysExt_success
    }

    // they click "Next" on the install sys ext success screen
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .locateMenuBarIcon // ...and go to locate icon
    }

    // they click "Next" on the locate menu bar icon screen
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .viewHealthCheck // ...and go to health check
    }

    // they click "Next" on the health check screen
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .howToUseGertrude // ...and go to how to use
    }

    // they click "Next" on the how to use screen
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .finish // ...and go to finish
    }

    // primary button on finish screen closes window, enables launch at login
    store.deps.app.isLaunchAtLoginEnabled = { false }
    let enableLaunchAtLogin = mock(always: ())
    store.deps.app.enableLaunchAtLogin = enableLaunchAtLogin.fn
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.windowOpen = false
    }
    await expect(enableLaunchAtLogin.invocations).toEqual(1)

    // shutdown tries fo flush keystrokes
    store.deps.monitoring = .mock
    store.deps.monitoring.takePendingKeystrokes = { nil }
    await store.send(.application(.willTerminate))
  }

  func testClickingTryAgainPrimaryFromInstallSysExtFailed() async {
    let store = featureStore { $0.step = .installSysExt_failed }
    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .installSysExt_explain
    }
  }

  func testClickingSkipSecondaryFromInstallSysExtFailed() async {
    let store = featureStore { $0.step = .installSysExt_failed }
    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .locateMenuBarIcon
    }
  }

  func testClickingHelpSecondaryFromInstallSysExt() async {
    let store = featureStore { $0.step = .installSysExt_allow }
    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .installSysExt_failed
    }
  }

  // for most users, we will move them along automatically to
  // success of failure based on the result of the install request,
  // but we do have a button as well, this tests that it works
  func testClickingDoneFromInstallSysExt() async {
    let store = featureStore { $0.step = .installSysExt_allow }
    let filterState = mock(returning: [FilterExtensionState.installedAndRunning])
    store.deps.filterExtension.state = filterState.fn

    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.installSysExt_success))
    await expect(filterState.invocations).toEqual(1)
  }

  func testHandleDetectingSysExtInstallFail() async {
    let store = featureStore {
      $0.step = .installSysExt_explain
    }
    store.deps.mainQueue = .immediate
    let filterState = mock(once: FilterExtensionState.notInstalled)
    store.deps.filterExtension.state = filterState.fn
    let installSysExt = mock(once: FilterInstallResult.timedOutWaiting) // <-- fail
    store.deps.filterExtension.install = installSysExt.fn

    // they click "Next" on the install sys ext explain screen
    await store.send(.webview(.primaryBtnClicked))
    await expect(installSysExt.invocations).toEqual(1)
    await store.receive(.setStep(.installSysExt_allow)) {
      $0.step = .installSysExt_allow // ...and go to sys ext allow
    }

    await store.receive(.setStep(.installSysExt_failed))
  }

  func testSysExtAlreadyInstalledAndRunning() async {
    let store = featureStore {
      $0.step = .installSysExt_explain
    }
    let filterState = mock(once: FilterExtensionState.installedAndRunning)
    store.deps.filterExtension.state = filterState.fn

    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.installSysExt_success)) {
      $0.step = .installSysExt_success
    }
  }

  func testSysExtAlreadyInstalledButNotRunning_StartsToSuccess() async {
    let store = featureStore { $0.step = .installSysExt_explain }
    let filterState = mock(once: FilterExtensionState.installedButNotRunning)
    store.deps.filterExtension.state = filterState.fn
    let filterStart = mock(once: FilterExtensionState.installedAndRunning)
    store.deps.filterExtension.start = filterStart.fn

    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.installSysExt_success)) {
      $0.step = .installSysExt_success
    }

    await expect(filterStart.invocations).toEqual(1)
  }

  func testSysExtAlreadyInstalledButNotRunning_StartFailsToError() async {
    let store = featureStore { $0.step = .installSysExt_explain }
    let filterState = mock(once: FilterExtensionState.installedButNotRunning)
    store.deps.filterExtension.state = filterState.fn
    let filterStart = mock(once: FilterExtensionState.installedButNotRunning)
    store.deps.filterExtension.start = filterStart.fn

    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.installSysExt_failed)) {
      $0.step = .installSysExt_failed
    }
  }

  func testSkipAllowKeylogging() async {
    let store = featureStore { $0.step = .allowKeylogging_required }
    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .installSysExt_explain
    }
  }

  func testFailedToAllowKeylogging() async {
    let store = featureStore { $0.step = .allowKeylogging_grant }
    let keyloggingAllowed = mock(always: false) // <-- they failed to allow
    store.deps.monitoring.keystrokeRecordingPermissionGranted = keyloggingAllowed.fn

    await store.send(.webview(.primaryBtnClicked))

    // ...and we check the setting and move to failure
    await expect(keyloggingAllowed.invocations).toEqual(1)
    await store.receive(.setStep(.allowKeylogging_failed)) {
      $0.step = .allowKeylogging_failed
    }

    let openSysPrefs = spy(on: SystemPrefsLocation.self, returning: ())
    store.deps.device.openSystemPrefs = openSysPrefs.fn

    // now they click the "try again" button
    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .allowKeylogging_grant
    }

    // and we tried to open system prefs to the right spot
    await expect(openSysPrefs.invocations).toEqual([.security(.accessibility)])
  }

  func testSkipsMostKeyloggingStepsIfPermsPreviouslyGranted() async {
    let store = featureStore { $0.step = .allowKeylogging_required }

    let keyloggingAllowed = mock(always: true) // <- they have granted permission
    store.deps.monitoring.keystrokeRecordingPermissionGranted = keyloggingAllowed.fn

    // they click "Grant permission" on the allow screenshots required screen
    await store.send(.webview(.primaryBtnClicked))

    // ...and we check the setting (which pops up prompt) and moved them on
    await expect(keyloggingAllowed.invocations).toEqual(1)
    await store.receive(.setStep(.installSysExt_explain)) {
      $0.step = .installSysExt_explain // ...and go to install system extension
    }
  }

  func testSkipAllowingScreenshots() async {
    let store = featureStore { $0.step = .allowScreenshots_required }
    // they click "Skip" on the allow screenshots start screen
    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .allowKeylogging_required // ...and go to keylogging
    }
  }

  func testSkipsMostScreenshotStepsIfPermsPreviouslyGranted() async {
    let store = featureStore { $0.step = .allowScreenshots_required }

    let screenshotsAllowed = mock(always: true) // <- they have granted permission
    store.deps.monitoring.screenRecordingPermissionGranted = screenshotsAllowed.fn

    // they click "Grant permission" on the allow screenshots required screen
    await store.send(.webview(.primaryBtnClicked))

    // ...and we check the setting (which pops up prompt) and moved them on
    await expect(screenshotsAllowed.invocations).toEqual(1)
    await store.receive(.setStep(.allowKeylogging_required)) {
      $0.step = .allowKeylogging_required // ...and go to keylogging
    }
  }

  func testFailureToGrantNotificationsSendsToFailScreen() async {
    let store = featureStore {
      $0.step = .allowNotifications_grant
    }

    let notifsSettings = mock(
      returning: [NotificationsSetting.none], // <- they did NOT enable notifications...
      then: NotificationsSetting.alert // ... but they fix it before we check again
    )
    store.deps.device.notificationsSetting = notifsSettings.fn

    // ... and then clicked "Done" on the notifications grant screen
    await store.send(.webview(.primaryBtnClicked))

    // ...and we fail to confirm the setting, moving them to fail screen
    await expect(notifsSettings.invocations).toEqual(1)
    await store.receive(.setStep(.allowNotifications_failed)) {
      $0.step = .allowNotifications_failed
    }

    // they fixed it, and clicked Try Again...
    await store.send(.webview(.primaryBtnClicked))

    // ...and we confirmed the setting and moved them on the happy path
    await expect(notifsSettings.invocations).toEqual(2)
    await store.receive(.setStep(.allowScreenshots_required)) {
      $0.step = .allowScreenshots_required
    }
  }

  func testSkipFromAllowNotificationsFailedStep() async {
    let store = featureStore {
      $0.step = .allowNotifications_failed
    }
    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .allowScreenshots_required
    }
  }

  func testSkipAllowNotificationsStep() async {
    let store = featureStore {
      $0.step = .allowNotifications_start
    }
    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .allowScreenshots_required
    }
  }

  func testNotificationsStepSkippedIfAlreadyGranted() async {
    let store = featureStore {
      $0.step = .connectChild
      $0.connectChildRequest = .succeeded(payload: "lil suzy")
      $0.existingNotificationsSetting = .alert // <-- already granted
    }

    // from the connect child success, they click next...
    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .allowScreenshots_required // ...and skip straight to screenshots
    }
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
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    store.deps.storage.loadPersistentState = { .init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .stable,
      filterVersion: "1.0.0",
      user: nil,
      resumeOnboarding: .at(step: .macosUserAccountType)
    ) }

    await store.send(.application(.didFinishLaunching))

    await store.receive(.onboarding(.resume(.at(step: .macosUserAccountType)))) {
      $0.onboarding.windowOpen = true
      $0.onboarding.step = .macosUserAccountType
    }

    await expect(saveState.invocations).toEqual([
      .init(
        appVersion: "1.0.0",
        appUpdateReleaseChannel: .stable,
        filterVersion: "1.0.0",
        user: nil,
        resumeOnboarding: nil // <-- nils out step
      ),
    ])
  }

  func testResumingCheckScreenRecordingGranted() async {
    let (store, _) = AppReducer.testStore()
    store.deps.monitoring.screenRecordingPermissionGranted = { true } // <-- granted
    store.deps.storage.loadPersistentState = { .init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .stable,
      filterVersion: "1.0.0",
      user: nil,
      resumeOnboarding: .checkingScreenRecordingPermission // <-- check
    ) }

    await store.send(.application(.didFinishLaunching))

    await store.receive(.onboarding(.setStep(.allowScreenshots_success))) {
      $0.onboarding.windowOpen = true
      $0.onboarding.step = .allowScreenshots_success
    }
  }

  func testResumingCheckScreenRecordingNotGranted() async {
    let (store, _) = AppReducer.testStore()
    store.deps.monitoring.screenRecordingPermissionGranted = { false } // <-- NOT granted
    store.deps.storage.loadPersistentState = { .init(
      appVersion: "1.0.0",
      appUpdateReleaseChannel: .stable,
      filterVersion: "1.0.0",
      user: nil,
      resumeOnboarding: .checkingScreenRecordingPermission // <-- check
    ) }

    await store.send(.application(.didFinishLaunching))

    await store.receive(.onboarding(.setStep(.allowScreenshots_failed))) {
      $0.onboarding.windowOpen = true
      $0.onboarding.step = .allowScreenshots_failed
    }

    let openSysPrefs = spy(on: SystemPrefsLocation.self, returning: ())
    store.deps.device.openSystemPrefs = openSysPrefs.fn

    // they now click the primary "try again" button
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .allowScreenshots_grantAndRestart // ... and go back to the grant step
    }

    // and we tried to open system prefs to the right spot
    await expect(openSysPrefs.invocations).toEqual([.security(.screenRecording)])
  }

  func testSkipFromScreenRecordingFailed() async {
    let store = featureStore {
      $0.step = .allowScreenshots_failed
    }
    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .allowKeylogging_required
    }
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
    store.deps.device.notificationsSetting = { .none }

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
    store.deps.device.notificationsSetting = { .none }

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
    store.deps.device.notificationsSetting = { .none }

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
  func featureStore(
    mutateState: @escaping (inout OnboardingFeature.State) -> Void = { _ in }
  ) -> TestStoreOf<OnboardingFeature.Reducer> {
    var state = OnboardingFeature.State()
    mutateState(&state)
    let store = TestStore(initialState: state) {
      OnboardingFeature.Reducer()
    }
    store.exhaustivity = .off
    return store
  }
}
