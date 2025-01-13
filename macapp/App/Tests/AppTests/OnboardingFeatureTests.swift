import ClientInterfaces
import Combine
import ComposableArchitecture
import Core
import Gertie
import MacAppRoute
import TestSupport
import XCore
import XCTest
import XExpect

@testable import App

final class OnboardingFeatureTests: XCTestCase {

  @MainActor
  func testFirstBootOnboardingHappyPathExhaustive() async {
    let (store, _) = AppReducer.testStore(exhaustive: true, mockDeps: false)
    let scheduler = DispatchQueue.test
    store.deps.backgroundQueue = scheduler.eraseToAnyScheduler()
    store.deps.mainQueue = .immediate
    store.deps.filterExtension.stateChanges = { Empty().eraseToAnyPublisher() }
    store.deps.filterXpc.events = { Empty().eraseToAnyPublisher() }
    store.deps.filterXpc.sendAlive = { .success(true) }
    store.deps.websocket.state = { .notConnected }
    store.deps.app.installLocation = { .inApplicationsDir }

    store.deps.device.currentUserId = { 502 }
    store.deps.device.listMacOSUsers = DeviceClient.mock.listMacOSUsers
    store.deps.device.notificationsSetting = { .none }

    store.deps.storage.loadPersistentState = { nil } // <-- first boot
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    let extSetup = mock(always: FilterExtensionState.notInstalled)
    store.deps.filterExtension.setup = extSetup.fn

    await store.send(.application(.didFinishLaunching))

    // ✅ section: welcome

    await store.receive(.loadedPersistentState(nil)) {
      $0.onboarding.windowOpen = true
      $0.onboarding.step = .welcome
    }

    await store.receive(.filter(.receivedState(.notInstalled))) {
      $0.filter.extension = .notInstalled
    }

    await expect(extSetup.calls.count).toEqual(1)
    await expect(saveState.calls.count).toEqual(1)

    // ✅ section: account

    // they click next on the welcome screen...
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .confirmGertrudeAccount // ... and go to confirm account
    }

    await store.receive(.onboarding(.receivedDeviceData(
      currentUserId: 502,
      users: [
        .init(id: 501, name: "Dad", type: .admin),
        .init(id: 502, name: "liljimmy", type: .standard),
      ]
    ))) {
      $0.onboarding.users = [
        .init(id: 501, name: "Dad", isAdmin: true),
        .init(id: 502, name: "liljimmy", isAdmin: false),
      ]
      $0.onboarding.currentUser = .init(id: 502, name: "liljimmy", isAdmin: false)
    }

    // ✅ section: child connection

    // next they confirm that they have a gertrude account...
    store.deps.device.currentMacOsUserType = { .standard }
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
    store.deps.app.installedVersion = { "1.0.0" }
    store.deps.device = .mock // lots of data used by connect user request
    let setUserToken = spy(on: UUID.self, returning: ())
    store.deps.api.setUserToken = setUserToken.fn

    // they enter code `123456` and click submit...
    await store.send(.onboarding(.webview(.connectChildSubmitted(code: 123_456)))) {
      $0.onboarding.step = .connectChild
      $0.onboarding.connectChildRequest = .ongoing // ... and see a throbber
    }

    await expect(setUserToken.calls).toEqual([UserData.mock.token])
    await expect(connectUser.calls.count).toEqual(1)
    await expect(connectUser.calls[0].verificationCode).toEqual(123_456)

    await store.receive(.onboarding(.connectUser(.success(user)))) {
      $0.user.data = user
      $0.history.userConnection = .established(welcomeDismissed: true)
      $0.onboarding.step = .connectChild
      $0.onboarding.connectChildRequest = .succeeded(payload: "lil suzy")
    }

    // we persisted the user data
    await expect(saveState.calls.count).toEqual(2)
    await expect(saveState.calls[1].user).toEqual(user)

    // notifications not enabled
    let notifsSettings = mock(returning: [.none], then: NotificationsSetting.alert)
    store.deps.device.notificationsSetting = notifsSettings.fn

    // they click "next" on the connected child success screen...
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .howToUseGifs // and go to "how to use gifs"
    }

    // they click "next" on the how to use gifs screen...
    await store.send(.onboarding(.webview(.primaryBtnClicked)))

    // ✅ section: notifications

    // ... and end up on the notifications screen
    await store.receive(.onboarding(.setStep(.allowNotifications_start))) {
      $0.onboarding.step = .allowNotifications_start
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
    await expect(requestNotifAuth.calls.count).toEqual(1)
    await expect(openSysPrefs.calls).toEqual([.notifications])

    // ✅ section: full disk access

    // the have not previously granted full disk access permission
    let hasFullDiskAccess = mock(returning: [false], then: true)
    store.deps.app.hasFullDiskAccess = hasFullDiskAccess.fn

    // ... and then clicked "Done" on the notifications grant screen
    await store.send(.onboarding(.webview(.primaryBtnClicked)))

    // ...and we confirmed the setting and moved them on the happy path
    await expect(notifsSettings.calls.count).toEqual(2)
    await store.receive(.onboarding(.setStep(.allowFullDiskAccess_grantAndRestart))) {
      $0.onboarding.step = .allowFullDiskAccess_grantAndRestart
    }

    // they click "Grant Permission" on the allow full disk acccess screen...
    await store.send(.onboarding(.webview(.primaryBtnClicked)))

    // ...we make a note to resume here after a quit/restart
    await store.receive(.onboarding(.delegate(.saveForResume(.checkingFullDiskAccessPermission))))
    // ...and we send them to the full disk access grant system prefs pane
    await expect(openSysPrefs.calls).toEqual([.notifications, .security(.fullDiskAccess)])

    // check that we persisted the onboarding resumption state
    await expect(saveState.calls.count).toEqual(3)
    await expect(saveState.calls[2].resumeOnboarding)
      .toEqual(.checkingFullDiskAccessPermission)

    // NB: here technically they RESTART the app, but instead of starting a new test
    // we simulate receiving the resume action to carry on where they should
    // we have other tests testing the resume from persisted state flow.
    await store.send(.onboarding(.resume(.checkingFullDiskAccessPermission)))

    await store.receive(.onboarding(.setStep(.allowFullDiskAccess_success))) {
      $0.onboarding.step = .allowFullDiskAccess_success
    }

    // ✅ section: screenshots

    // they have not previously granted screenshot permission...
    let screenshotsAllowed = mock(returning: [false, false], then: true)
    store.deps.monitoring.screenRecordingPermissionGranted = screenshotsAllowed.fn

    // they click the "Next" button from the full disk success
    await store.send(.onboarding(.webview(.primaryBtnClicked)))
    await store.receive(.onboarding(.setStep(.allowScreenshots_required))) {
      $0.onboarding.step = .allowScreenshots_required
    }

    let takeScreenshot = spy(on: Int.self, returning: ())
    store.deps.monitoring.takeScreenshot = takeScreenshot.fn

    // they click "Grant Permission" on the allow screenshots start screen
    await store.send(.onboarding(.webview(.primaryBtnClicked)))

    await store.receive(.onboarding(.delegate(.saveForResume(.checkingScreenRecordingPermission))))

    // check that we persisted the onboarding resumption state
    await expect(saveState.calls.count).toEqual(4)
    await expect(saveState.calls[3].resumeOnboarding)
      .toEqual(.checkingScreenRecordingPermission)

    await store.receive(.onboarding(.setStep(.allowScreenshots_grantAndRestart))) {
      $0.onboarding.step = .allowScreenshots_grantAndRestart
    }

    // ...and we check the setting, and take a screenshot, and moved them on
    await expect(screenshotsAllowed.calls.count).toEqual(2)
    // taking a screenshot ensures the full permissions prompt
    await expect(takeScreenshot.calls.count).toEqual(1)

    let preventNag = mock(returning: [Result<Void, StringError>.success(())])
    store.deps.app.preventScreenCaptureNag = preventNag.fn

    // NB: here technically they RESTART the app, but instead of starting a new test
    // we simulate receiving the resume action to carry on where they should
    // we have other tests testing the resume from persisted state flow.
    await store.send(.onboarding(.resume(.checkingScreenRecordingPermission)))

    await store.receive(.onboarding(.setStep(.allowScreenshots_success))) {
      $0.onboarding.step = .allowScreenshots_success
    }

    // we've come back from restart with good permissions, so we proactively
    // fix the screen capture approvals file so that the next screen capture
    // will not be nagged. we also take a screenshot to that just in case they
    // are notified, they are still in the mode of granting permissions
    await expect(preventNag.calls.count).toEqual(1)
    await expect(takeScreenshot.calls.count).toEqual(2)

    // ✅ section: keylogging

    // they click the "Next" button from the screen recording success
    await store.send(.onboarding(.webview(.primaryBtnClicked)))
    await store.receive(.onboarding(.delegate(.saveForResume(nil))))
    await store.receive(.onboarding(.setStep(.allowKeylogging_required))) {
      $0.onboarding.step = .allowKeylogging_required
    }

    // they have not previously granted permission...
    let keyloggingAllowed = mock(returning: [false], then: true)
    store.deps.monitoring.keystrokeRecordingPermissionGranted = keyloggingAllowed.fn

    // they click "Grant Permission" on the allow keylogging start screen
    await store.send(.onboarding(.webview(.primaryBtnClicked)))

    await store.receive(.onboarding(.delegate(.saveForResume(nil))))
    await store.receive(.onboarding(.setStep(.allowKeylogging_grant))) {
      $0.onboarding.step = .allowKeylogging_grant // ...and go to grant
    }

    // ...and we checked the setting (which pops up prompt) and moved them on
    await expect(keyloggingAllowed.calls.count).toEqual(1)

    // ✅ section: system extension

    // moving on from keylogging tests filter extension state, to possibly skip
    let filterState = mock(returning: [
      FilterExtensionState.notInstalled,
      .notInstalled,
      .installedAndRunning,
    ])
    store.deps.filterExtension.state = filterState.fn

    // they click "Done" indicating they think they've allowed keylogging
    await store.send(.onboarding(.webview(.primaryBtnClicked)))

    // we confirm, and see that they did it correct...
    await expect(keyloggingAllowed.calls.count).toEqual(2)
    // ...so they get sent off to the next happy path step
    await store.receive(.onboarding(.delegate(.saveForResume(nil))))
    await store.receive(.onboarding(.setStep(.installSysExt_explain))) {
      $0.onboarding.step = .installSysExt_explain // ...which is sys ext explain
    }

    // they click "Got it" on the install sys ext start screen
    await store.send(.onboarding(.webview(.primaryBtnClicked)))
    await store.receive(.onboarding(.setStep(.installSysExt_trick))) {
      $0.onboarding.step = .installSysExt_trick // ...which is sys ext "trick"
    }

    let installSysExt = spy(
      on: Int.self,
      returning: FilterInstallResult.installedSuccessfully // <-- success
    )
    store.deps.filterExtension.installOverridingTimeout = installSysExt.fn

    let setUserExemption = spy2(
      on: (uid_t.self, Bool.self),
      returning: Result<Void, XPCErr>.success(())
    )
    store.deps.filterXpc.setUserExemption = setUserExemption.fn

    let getUserTypes = mock(
      always: Result<FilterUserTypes, XPCErr>
        .success(.init(exempt: [], protected: []))
    )
    store.deps.filterXpc.requestUserTypes = getUserTypes.fn

    // they click "Got it" on the install sys ext trick screen...
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .installSysExt_allow // ...and go to sys ext allow...
    }

    // ...which kicks off the sys ext install
    await expect(installSysExt.calls.count).toEqual(1)

    // because filterExtension.install is mocked to return success, we go to success
    await store.receive(.onboarding(.setStep(.installSysExt_success))) {
      $0.onboarding.step = .installSysExt_success
    }

    // we clear the exempted state for the current user proactively as safeguard
    await expect(setUserExemption.calls).toEqual([.init(502, false)])

    await expect(getUserTypes.calls.count).toEqual(1)
    await store.receive(.onboarding(.receivedFilterUsers(.init(exempt: [], protected: [])))) {
      $0.onboarding.filterUsers = .init(exempt: [], protected: [])
    }

    // 🔐 start protection actions

    // we kick off protection when they move past sys ext stage, lots happens...
    let setAccountActive = spy(on: Bool.self, returning: ())
    store.deps.api.setAccountActive = setAccountActive.fn
    let checkInResult = CheckIn_v2.Output.empty {
      $0.userData = user
      $0.trustedTime = (Date.reference - 1).timeIntervalSince1970
    }
    let checkIn = spy(on: CheckIn.Input.self, returning: checkInResult)
    store.deps.api.checkIn = checkIn.fn
    store.deps.websocket.receive = { Empty().eraseToAnyPublisher() }
    let connectWebsocket = succeed(with: WebSocketClient.State.connected, capturing: UUID.self)
    store.deps.websocket.connect = connectWebsocket.fn
    let wsSend = succeed(with: (), capturing: WebSocketMessage.FromAppToApi.self)
    store.deps.websocket.send = wsSend.fn
    store.deps.monitoring = .mock
    let stopLoggingKeystrokes = mock(always: ())
    store.deps.monitoring.stopLoggingKeystrokes = stopLoggingKeystrokes.fn
    let startRelaunchWatcher = mock(always: ())
    store.deps.app.startRelaunchWatcher = startRelaunchWatcher.fn
    store.deps.date = .constant(.reference)
    store.deps.device.boottime = { .reference - 60 }
    let preventScreenCaptureNag = mock(always: Result<Void, StringError>.success(()))
    store.deps.app.preventScreenCaptureNag = preventScreenCaptureNag.fn

    // ✅ section: exempt users and wrap-up

    // they click "Next" on the install sys ext success screen
    // NB: this actually kicks off the `.startProtecting` sequence
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .exemptUsers // ...and go to exempt users
    }

    // this proves that we turned on all monitoring
    await expect(stopLoggingKeystrokes.calls.count).toEqual(1)

    await store.receive(.onboarding(.delegate(.onboardingConfigComplete)))
    await store.receive(.startProtecting(user: user))
    await store.receive(.networkConnectionChanged(connected: true))
    await store.receive(.websocket(.connectedSuccessfully))

    await store.receive(.checkIn(result: .success(checkInResult), reason: .startProtecting)) {
      $0.appUpdates.latestVersion = checkInResult.latestRelease
    }

    let timestamp = TrustedTimestamp(
      network: .reference - 1,
      system: .reference,
      boottime: .reference - 60
    )
    await store.receive(.setTrustedTimestamp(timestamp)) {
      $0.timestamp = timestamp
    }

    await store.receive(.user(.updated(previous: user)))

    // we need to ensure the websocket connection is setup, so they can do the tutorial vid
    await expect(connectWebsocket.calls).toEqual([UserData.mock.token])
    await expect(wsSend.calls).toEqual([.currentFilterState(.off)])

    await expect(setUserToken.calls).toEqual([UserData.mock.token, UserData.mock.token])
    await expect(setAccountActive.calls).toEqual([true])
    await expect(startRelaunchWatcher.calls.count).toEqual(1)
    await expect(preventScreenCaptureNag.calls.count).toEqual(1)

    // they click to exempt the dad admin user
    await store.send(.onboarding(.webview(.setUserExemption(userId: 501, enabled: true)))) {
      $0.onboarding.filterUsers = .init(exempt: [501], protected: [])
    }
    await expect(setUserExemption.calls).toEqual([.init(502, false), .init(501, true)])

    // now they click continue from the exempt users screen...
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

    // primary button on finish screen closes window, sends delegate that starts protection
    store.deps.app.isLaunchAtLoginEnabled = { false }
    let enableLaunchAtLogin = mock(always: ())
    store.deps.app.enableLaunchAtLogin = enableLaunchAtLogin.fn

    // close the final "finish" screen
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.windowOpen = false
    }

    await expect(checkIn.calls).toEqual([.init(
      appVersion: "1.0.0",
      filterVersion: "1.0.0",
      userIsAdmin: false,
      osVersion: "14.0.0"
    )])
    await expect(enableLaunchAtLogin.calls.count).toEqual(1)

    // shutdown tries fo flush keystrokes
    store.deps.monitoring.takePendingKeystrokes = { nil }
    // and stop relauncher
    let stopRelaunchWatcher = mock(always: ())
    store.deps.app.stopRelaunchWatcher = stopRelaunchWatcher.fn

    await store.send(.application(.willTerminate))

    await expect(stopRelaunchWatcher.calls.count).toEqual(1)
  }

  @MainActor
  func testSingleUserOnlySkipsExemptUserScreen() async {
    let store = self.featureStore {
      $0.step = .installSysExt_success
      $0.users = [.init(id: 501, name: "Dad", isAdmin: true)]
      $0.filterUsers = .init(exempt: [], protected: [])
    }

    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .locateMenuBarIcon
    }
  }

  @MainActor
  func testDoesntSkipExemptScreenIfOtherUsers() async {
    let store = self.featureStore {
      $0.step = .installSysExt_success
      $0.currentUser = .init(id: 502, name: "Lil jimmy", isAdmin: false)
      $0.users = [
        .init(id: 501, name: "Dad", isAdmin: true),
        .init(id: 502, name: "Lil jimmy", isAdmin: false),
      ]
      $0.filterUsers = .init(exempt: [], protected: [501]) // <-- Dad is protected
    }

    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .exemptUsers // <-- but we still show him
    }
  }

  @MainActor
  func testAppNotInRootApplicationsDir() async {
    let (store, _) = AppReducer.testStore(exhaustive: false, mockDeps: true)
    let quit = mock(always: ())
    store.deps.storage.loadPersistentState = { nil }
    store.deps.app.quit = quit.fn
    store.deps.app.installLocation = {
      // !! not correct dir, macOS won't install sys ext from there
      URL(fileURLWithPath: "/Users/jared/Desktop/Gertrude.app")
    }

    await store.send(.application(.didFinishLaunching))

    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .wrongInstallDir
    }

    await expect(quit.calls.count).toEqual(0)
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.windowOpen = false
    }

    await expect(quit.calls.count).toEqual(1)
  }

  @MainActor
  func testBailingBeforeConnectionQuitsForReOnboarding() async {
    let (store, _) = AppReducer.testStore(exhaustive: false, mockDeps: true)
    let loadState = mock(
      returning: [nil], // <-- first boot
      then: Persistent.State( // <-- quit+delete failsave, w/ no user
        appVersion: "1.0.0",
        appUpdateReleaseChannel: .stable,
        filterVersion: "1.0.0"
      )
    )
    store.deps.storage.loadPersistentState = loadState.fn
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    let deleteAll = mock(always: ())
    store.deps.storage.deleteAll = deleteAll.fn
    let quit = mock(always: ())
    store.deps.app.quit = quit.fn

    await store.send(.application(.didFinishLaunching))

    await store.receive(.loadedPersistentState(nil)) {
      $0.onboarding.windowOpen = true
      $0.onboarding.step = .welcome
    }

    await expect(saveState.calls.count).toEqual(1)

    await store.send(.onboarding(.webview(.primaryBtnClicked))) // welcome -> confirm acct
    await store.send(.onboarding(.webview(.primaryBtnClicked))) // confirm acct -> get code
    await store.send(.onboarding(.webview(.primaryBtnClicked))) { // get code -> connect child
      $0.onboarding.step = .connectChild
    }

    // this is the initial save in AppReducer, after loading nil, it has NO user
    await expect(saveState.calls).toEqual([
      .init(appVersion: "1.0.0", appUpdateReleaseChannel: .stable, filterVersion: "1.0.0"),
    ])

    // we haven't called deleteAll (or quit) yet...
    await expect(deleteAll.calls.count).toEqual(0)
    await expect(quit.calls.count).toEqual(0)
    await expect(loadState.calls.count).toEqual(1) // and only loaded state once

    // ...and we NEVER call save state again
    store.deps.storage.savePersistentState = {
      _ in fatalError("not called again")
    }

    store.assert {
      // double-check no user data from connection whatsoever
      $0.onboarding.connectChildRequest = .idle
      $0.user = .init()
    }

    // now they CLOSE the onboarding flow
    await store.send(.onboarding(.webview(.closeWindow))) {
      $0.onboarding.windowOpen = false
    }

    // so we purge all stored state (so onboarder runs next launch), and quit
    await expect(deleteAll.calls.count).toEqual(1)
    await expect(quit.calls.count).toEqual(1)
    await expect(loadState.calls.count).toEqual(2) // the failsafe check, for state.user = nil
  }

  @MainActor
  func testResumingFromAdminUserDemotion() async {
    let (store, _) = AppReducer.testStore(mockDeps: true)
    store.deps.device = .testValue
    store.deps.device.currentUserId = { 502 }
    store.deps.device.listMacOSUsers = { [
      .init(id: 501, name: "jared", type: .admin),
      .init(id: 502, name: "franny", type: .standard),
    ] }

    store.deps.storage.loadPersistentState = { .mock {
      $0.user = .monitored
      $0.resumeOnboarding = .at(step: .macosUserAccountType)
    }}

    await store.send(.application(.didFinishLaunching))
    await store.receive(.onboarding(.resume(.at(step: .macosUserAccountType)))) {
      $0.onboarding.step = .macosUserAccountType
      $0.onboarding.windowOpen = true
    }

    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .getChildConnectionCode
      // we need to make sure we initialize the user data when resuming
      $0.onboarding.currentUser = .init(id: 502, name: "franny", isAdmin: false)
      $0.onboarding.users = [
        .init(id: 501, name: "jared", isAdmin: true),
        .init(id: 502, name: "franny", isAdmin: false),
      ]
    }
  }

  @MainActor
  func testResumingToCheckScreenRecordingRestoresUserConnection() async {
    let (store, _) = AppReducer.testStore()
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.monitoring.screenRecordingPermissionGranted = { true }
    store.deps.storage.savePersistentState = saveState.fn
    store.deps.api.checkIn = { _ in throw TestErr("stop checkin") }
    store.deps.app.isLaunchAtLoginEnabled = { fatalError("don't check launch at login") }

    // it's critical this is not called when we first resume, so that they
    // don't get a prompt until they advance to the keylogging screen
    store.deps.monitoring.keystrokeRecordingPermissionGranted = {
      fatalError("keystrokeRecordingPermissionGranted should not be called")
    }

    store.deps.storage.loadPersistentState = { .mock {
      $0.user = .mock { $0.keyloggingEnabled = true }
      $0.resumeOnboarding = .checkingScreenRecordingPermission // <-- resume here
    }}

    await store.send(.application(.didFinishLaunching))
    await store.skipReceivedActions()

    store.assert {
      $0.onboarding.windowOpen = true
      $0.onboarding.step = .allowScreenshots_success
      // user restored
      $0.onboarding.connectChildRequest = .succeeded(payload: UserData.mock.name)
      $0.user = .init(data: .mock { $0.keyloggingEnabled = true })
    }

    // and we saved the state, removing onboarding resume
    await expect(saveState.calls).toEqual([.mock {
      $0.user = .mock { $0.keyloggingEnabled = true }
      $0.resumeOnboarding = nil
    }])
  }

  @MainActor
  func testResumingToCheckScreenRecording_Failure() async {
    let (store, _) = AppReducer.testStore()
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.monitoring.screenRecordingPermissionGranted = { false } // <-- still no bueno!
    store.deps.storage.savePersistentState = saveState.fn
    store.deps.api.checkIn = { _ in throw TestErr("stop checkin") }
    store.deps.app.isLaunchAtLoginEnabled = { fatalError("don't check launch at login") }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { fatalError("nope") }

    store.deps.storage.loadPersistentState = { .mock {
      $0.user = .mock { $0.keyloggingEnabled = true }
      $0.resumeOnboarding = .checkingScreenRecordingPermission // <-- resume here
    }}

    await store.send(.application(.didFinishLaunching))
    await store.skipReceivedActions()

    store.assert {
      $0.onboarding.step = .allowScreenshots_failed
    }

    // since the perms are still wrong, we need to save state to
    // resume again after a quit & restart
    await expect(saveState.calls).toEqual([
      .mock {
        $0.user = .mock { $0.keyloggingEnabled = true }
        $0.resumeOnboarding = nil // <-- the first, default clear save
      },
      .mock {
        $0.user = .mock { $0.keyloggingEnabled = true }
        $0.resumeOnboarding = .checkingScreenRecordingPermission // <-- after we detect the failure
      },
    ])
  }

  @MainActor
  func testQuittingOnboardingEarlyAfterConnectionSuccessStartsProtection() async {
    let (store, _) = AppReducer.testStore {
      $0.user = .init(data: .mock { $0.name = "franny" })
      $0.onboarding.step = .allowNotifications_start // post child connection..
      $0.onboarding
        .connectChildRequest = .succeeded(payload: "franny") // <-- ... w/ a successful connection
    }

    await store.send(.onboarding(.webview(.closeWindow)))
    await store.receive(.startProtecting(user: .mock { $0.name = "franny" }))
  }

  @MainActor
  func testSkippingFromAdminUserRemediation() async {
    let store = self.featureStore {
      $0.step = .macosUserAccountType
      $0.userRemediationStep = .create
    }
    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .getChildConnectionCode
    }
  }

  @MainActor
  func testPrimaryBtnFromAllowScreenshotsGrantModalGoesToFailForVideo() async {
    let store = self.featureStore { $0.step = .allowScreenshots_grantAndRestart }
    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .allowScreenshots_failed
    }
  }

  @MainActor
  func testSecondaryEscapeHatchFromAllowScreenshotsGrantGoesToNextStage() async {
    let store = self.featureStore { $0.step = .allowScreenshots_grantAndRestart }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { false }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.allowKeylogging_required))
  }

  @MainActor
  func testSecondaryFromAllowNotificationsGrantModalGoesToFail() async {
    let store = self.featureStore { $0.step = .allowNotifications_grant }
    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .allowNotifications_failed
    }
  }

  @MainActor
  func testSkippingAllStepsFromConnectSuccess() async {
    let store = self.featureStore {
      $0.step = .connectChild
      $0.connectChildRequest = .succeeded(payload: "Lil jimmy")
    }

    store.deps.device.notificationsSetting = { .alert }
    store.deps.app.hasFullDiskAccess = { true }
    store.deps.monitoring.screenRecordingPermissionGranted = { true }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { true }
    store.deps.filterExtension.state = { .installedAndRunning }

    await store.send(.webview(.primaryBtnClicked)) { $0.step = .howToUseGifs }
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowKeylogging_required)) // we always stop here
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.locateMenuBarIcon))
  }

  @MainActor
  func testSkippingNotificationStepFromConnectSuccess() async {
    let store = self.featureStore {
      $0.step = .connectChild
      $0.connectChildRequest = .succeeded(payload: "Lil jimmy")
    }

    store.deps.device.notificationsSetting = { .alert }
    store.deps.app.hasFullDiskAccess = { false }
    store.deps.monitoring.screenRecordingPermissionGranted = { fatalError() }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { fatalError() }
    store.deps.filterExtension.state = { fatalError() }

    await store.send(.webview(.primaryBtnClicked)) { $0.step = .howToUseGifs }
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowFullDiskAccess_grantAndRestart))
  }

  @MainActor
  func testSkippingToKeyloggingFromConnectSuccess() async {
    let store = self.featureStore {
      $0.step = .connectChild
      $0.connectChildRequest = .succeeded(payload: "Lil jimmy")
    }

    store.deps.device.notificationsSetting = { .alert }
    store.deps.monitoring.screenRecordingPermissionGranted = { true }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { false }
    store.deps.filterExtension.state = { fatalError() }
    store.deps.app.hasFullDiskAccess = { true }

    await store.send(.webview(.primaryBtnClicked)) { $0.step = .howToUseGifs }
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowKeylogging_required))
  }

  @MainActor
  func testSkippingToInstallSysExtFromConnectSuccess() async {
    let store = self.featureStore {
      $0.step = .connectChild
      $0.connectChildRequest = .succeeded(payload: "Lil jimmy")
    }

    store.deps.device.notificationsSetting = { .alert }
    store.deps.monitoring.screenRecordingPermissionGranted = { true }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { true }
    store.deps.filterExtension.state = { .notInstalled }
    store.deps.app.hasFullDiskAccess = { true }

    await store.send(.webview(.primaryBtnClicked)) { $0.step = .howToUseGifs }
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowKeylogging_required)) // we always stop here
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.installSysExt_explain))
  }

  @MainActor
  func testFullDiskAccessFromFinishNotifications() async {
    let store = self.featureStore { $0.step = .allowNotifications_grant }
    store.deps.app.hasFullDiskAccess = { true } // <-- skip
    store.deps.monitoring.screenRecordingPermissionGranted = { false }
    store.deps.device.notificationsSetting = { .alert }
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowScreenshots_required))
  }

  @MainActor
  func testSkippingScreenshotsFromFinishFullDiskAccess() async {
    let store = self.featureStore { $0.step = .allowFullDiskAccess_success }
    store.deps.monitoring.screenRecordingPermissionGranted = { true } // <-- skip
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { false }
    store.deps.device.notificationsSetting = { .alert }
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowKeylogging_required))
  }

  @MainActor
  func testSkippingKeyloggingFromFinishScreenshots() async {
    let store = self.featureStore { $0.step = .allowScreenshots_success }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { true }
    store.deps.filterExtension.state = { .notInstalled }
    await store.send(.webview(.primaryBtnClicked))
    // we always stop here, because we can't check without prompting
    await store.receive(.setStep(.allowKeylogging_required))
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.installSysExt_explain)) // <-- but they skip the rest
  }

  @MainActor
  func testFromScreenshotsRequiredScreenshotsAndKeyloggingAlreadyAllowed() async {
    let store = self.featureStore { $0.step = .allowScreenshots_required }
    store.deps.monitoring.screenRecordingPermissionGranted = { true }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { true }
    store.deps.filterExtension.state = { .notInstalled }
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowKeylogging_required)) // we always stop here
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.installSysExt_explain))
  }

  @MainActor
  func testClickingTryAgainPrimaryFromInstallSysExtFailed() async {
    let store = self.featureStore { $0.step = .installSysExt_failed }
    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .installSysExt_explain
    }
  }

  @MainActor
  func testClickingSkipSecondaryFromInstallSysExtFailed() async {
    let store = self.featureStore { $0.step = .installSysExt_failed }
    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .locateMenuBarIcon
    }
  }

  @MainActor
  func testClickingHelpSecondaryFromInstallSysExt() async {
    let store = self.featureStore { $0.step = .installSysExt_allow }
    store.deps.filterExtension.state = { .notInstalled } // <-- not installed
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.installSysExt_failed)) // <-- goes to failed
  }

  @MainActor
  func testClickingHelpSecondaryFromInstallSysExt_WhenInstalled() async {
    let store = self.featureStore { $0.step = .installSysExt_allow }
    store.deps.filterExtension.state = { .installedAndRunning } // <-- installed
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.installSysExt_success)) // <-- goes to success
  }

  // for most users, we will move them along automatically to
  // success of failure based on the result of the install request,
  // but we do have a button as well, this tests that it works
  @MainActor
  func testClickingDoneFromInstallSysExt() async {
    let store = self.featureStore { $0.step = .installSysExt_allow }
    let filterState = mock(returning: [FilterExtensionState.installedAndRunning])
    store.deps.filterExtension.state = filterState.fn

    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.installSysExt_success))
    await expect(filterState.calls.count).toEqual(1)
  }

  @MainActor
  func testHandleDetectingSysExtInstallFail() async {
    let store = self.featureStore {
      $0.step = .installSysExt_trick
    }
    store.deps.mainQueue = .immediate
    let filterState = mock(once: FilterExtensionState.notInstalled)
    store.deps.filterExtension.state = filterState.fn
    let installSysExt = spy(
      on: Int.self,
      returning: FilterInstallResult.userClickedDontAllow // <-- fail
    )
    store.deps.filterExtension.installOverridingTimeout = installSysExt.fn

    // they click "Next" on the install sys ext "trick" screen...
    await store.send(.webview(.primaryBtnClicked)) {
      // which brings them to the "allow" screen, AND kicks of (unsuccesful) install
      $0.step = .installSysExt_allow
    }

    // prove we tried to install (which was mocked to fail)
    await expect(installSysExt.calls.count).toEqual(1)
    // so we end up on fail screen
    await store.receive(.setStep(.installSysExt_failed))
  }

  @MainActor
  func testSysExtAlreadyInstalledAndRunning() async {
    let store = self.featureStore { $0.step = .installSysExt_explain }
    let filterState = mock(once: FilterExtensionState.installedAndRunning)
    store.deps.filterExtension.state = filterState.fn

    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.installSysExt_success)) {
      $0.step = .installSysExt_success
    }
  }

  @MainActor
  func testSysExtAlreadyInstalledButNotRunning_StartsToSuccess() async {
    let store = self.featureStore { $0.step = .installSysExt_explain }
    let filterState = mock(once: FilterExtensionState.installedButNotRunning)
    store.deps.filterExtension.state = filterState.fn
    let filterStart = mock(once: FilterExtensionState.installedAndRunning)
    store.deps.filterExtension.start = filterStart.fn

    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.installSysExt_success)) {
      $0.step = .installSysExt_success
    }

    await expect(filterStart.calls.count).toEqual(1)
  }

  @MainActor
  func testSysExtAlreadyInstalledButNotRunning_StartFailsToError() async {
    let store = self.featureStore { $0.step = .installSysExt_explain }
    let filterState = mock(once: FilterExtensionState.installedButNotRunning)
    store.deps.filterExtension.state = filterState.fn
    let filterStart = mock(once: FilterExtensionState.installedButNotRunning)
    store.deps.filterExtension.start = filterStart.fn

    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.installSysExt_failed)) {
      $0.step = .installSysExt_failed
    }
  }

  @MainActor
  func testSkipAllowKeylogging() async {
    let store = self.featureStore { $0.step = .allowKeylogging_required }
    store.deps.filterExtension.state = { .notInstalled }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.installSysExt_explain))
  }

  @MainActor
  func testSkipAllowKeyloggingSysExtAlreadyInstalled() async {
    let store = self.featureStore { $0.step = .allowKeylogging_required }
    store.deps.filterExtension.state = { .installedAndRunning }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.locateMenuBarIcon))
  }

  @MainActor
  func testFailedToAllowKeylogging() async {
    let store = self.featureStore { $0.step = .allowKeylogging_grant }
    let keyloggingAllowed = mock(always: false) // <-- they failed to allow
    store.deps.monitoring.keystrokeRecordingPermissionGranted = keyloggingAllowed.fn

    await store.send(.webview(.primaryBtnClicked))

    // ...and we check the setting and move to failure
    await expect(keyloggingAllowed.calls.count).toEqual(1)
    await store.receive(.setStep(.allowKeylogging_failed)) {
      $0.step = .allowKeylogging_failed
    }

    let openSysPrefs = spy(on: SystemPrefsLocation.self, returning: ())
    store.deps.device.openSystemPrefs = openSysPrefs.fn

    // now they click the "try again" button
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowKeylogging_grant))

    // and we tried to open system prefs to the right spot
    await expect(openSysPrefs.calls).toEqual([.security(.accessibility)])
  }

  @MainActor
  func testSkipFromKeylogginFail() async {
    let store = self.featureStore { $0.step = .allowKeylogging_failed }
    store.deps.filterExtension.state = { .notInstalled }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.installSysExt_explain))
  }

  @MainActor
  func testSkipsMostKeyloggingStepsIfPermsPreviouslyGranted() async {
    let store = self.featureStore { $0.step = .allowKeylogging_required }

    let keyloggingAllowed = mock(always: true) // <- they have granted permission
    store.deps.monitoring.keystrokeRecordingPermissionGranted = keyloggingAllowed.fn
    store.deps.filterExtension.state = { .notInstalled }

    // they click "Grant permission" on the allow screenshots required screen
    await store.send(.webview(.primaryBtnClicked))

    // ...and we check the setting (which pops up prompt) and moved them on
    await expect(keyloggingAllowed.calls.count).toEqual(1)
    await store.receive(.setStep(.installSysExt_explain))
  }

  @MainActor
  func testSkipAllowingScreenshots() async {
    let store = self.featureStore { $0.step = .allowScreenshots_required }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { false }
    // they click "Skip" on the allow screenshots start screen
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.allowKeylogging_required))
  }

  @MainActor
  func testSkipsMostScreenshotStepsIfPermsPreviouslyGranted() async {
    let store = self.featureStore { $0.step = .allowScreenshots_required }

    let screenshotsAllowed = mock(always: true) // <- they have granted permission
    store.deps.monitoring.screenRecordingPermissionGranted = screenshotsAllowed.fn
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { false }

    // they click "Grant permission" on the allow screenshots required screen
    await store.send(.webview(.primaryBtnClicked))

    // ...and we check the setting (which pops up prompt) and moved them on
    await expect(screenshotsAllowed.calls.count).toEqual(1)
    await store.receive(.setStep(.allowKeylogging_required)) {
      $0.step = .allowKeylogging_required // ...and go to keylogging
    }
  }

  @MainActor
  func testFailureToGrantNotificationsSendsToFailScreen() async {
    let store = self.featureStore { $0.step = .allowNotifications_grant }

    let notifsSettings = mock(
      // they did NOT enable notifications (the first 2 times we check)
      returning: [NotificationsSetting.none, .none],
      then: NotificationsSetting.alert // ... but they fix it before 3rd...
    )
    store.deps.device.notificationsSetting = notifsSettings.fn

    // ... and then clicked "Done" on the notifications grant screen
    await store.send(.webview(.primaryBtnClicked))

    // ...and we fail to confirm the setting, moving them to fail screen
    await expect(notifsSettings.calls.count).toEqual(1)
    await store.receive(.setStep(.allowNotifications_failed))

    let requestNotifAuth = mock(always: ())
    store.deps.device.requestNotificationAuthorization = requestNotifAuth.fn
    let openSysPrefs = spy(on: SystemPrefsLocation.self, returning: ())
    store.deps.device.openSystemPrefs = openSysPrefs.fn

    // they did NOT fix it, and clicked Try Again...
    await store.send(.webview(.primaryBtnClicked))

    // so we a) checked the settings again
    await expect(notifsSettings.calls.count).toEqual(2)
    // b) requested permission
    await expect(requestNotifAuth.calls.count).toEqual(1)
    // and c) open system prefs
    await expect(openSysPrefs.calls).toEqual([.notifications])
    // and send them back to the grant screen with instructions
    await store.receive(.setStep(.allowNotifications_grant))

    // NOW (3rd check) they finally fixed it, and clicked Try Again...
    store.deps.app.hasFullDiskAccess = { false }
    await store.send(.webview(.primaryBtnClicked))

    // ...and we confirmed the setting and moved them on the happy path
    await expect(notifsSettings.calls.count).toEqual(3)
    await store.receive(.setStep(.allowFullDiskAccess_grantAndRestart))
  }

  @MainActor
  func testSkipFromAllowNotificationsFailedStep() async {
    let store = self.featureStore { $0.step = .allowNotifications_failed }
    store.deps.app.hasFullDiskAccess = { false }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.allowFullDiskAccess_grantAndRestart))
  }

  @MainActor
  func testSkipAllowNotificationsStep() async {
    let store = self.featureStore { $0.step = .allowNotifications_start }
    store.deps.app.hasFullDiskAccess = { false }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.allowFullDiskAccess_grantAndRestart))
  }

  @MainActor
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
    await expect(openWebUrl.calls).toEqual([.init(string: "https://gertrude.app/contact")!])

    // they clicked "try again"
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .getChildConnectionCode
      $0.onboarding.connectChildRequest = .idle
    }
  }

  @MainActor
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

    await expect(saveState.calls).toEqual([
      .init(
        appVersion: "1.0.0",
        appUpdateReleaseChannel: .stable,
        filterVersion: "1.0.0",
        user: nil,
        resumeOnboarding: nil // <-- nils out step
      ),
    ])
  }

  @MainActor
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

  @MainActor
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
    await store.send(.onboarding(.webview(.primaryBtnClicked)))
    await store.receive(.onboarding(.setStep(.allowScreenshots_grantAndRestart)))

    // and we tried to open system prefs to the right spot
    await expect(openSysPrefs.calls).toEqual([.security(.screenRecording)])
  }

  @MainActor
  func testTryAgainFromScreenRecFailMovesOnIfPermsGranted() async {
    let store = self.featureStore { $0.step = .allowScreenshots_failed }
    store.deps.monitoring.screenRecordingPermissionGranted = { true }
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowScreenshots_success))
  }

  @MainActor
  func testSkipFromScreenRecordingFailed() async {
    let store = self.featureStore { $0.step = .allowScreenshots_failed }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { false }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.allowKeylogging_required))
  }

  @MainActor
  func testNoGertrudeAccountPrimary() async {
    let store = self.featureStore { $0.step = .noGertrudeAccount }
    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .macosUserAccountType
    }
  }

  @MainActor
  func testSecondaryHelpFromAllowKeyloggingGrantGoesToFailForVideo() async {
    let store = self.featureStore { $0.step = .allowKeylogging_grant }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { false }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.allowKeylogging_failed))
  }

  @MainActor
  func testSecondaryHelpFromAllowKeyloggingGrantGoesToNextIfPermGranted() async {
    let store = self.featureStore { $0.step = .allowKeylogging_grant }
    store.deps.monitoring.keystrokeRecordingPermissionGranted = { true } // <-- granted
    store.deps.filterExtension.state = { .notInstalled }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.installSysExt_explain))
  }

  @MainActor
  func testNoGertrudeAccountQuit() async {
    let store = self.featureStore()
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
    await expect(deleteAll.called).toEqual(true)
    await expect(quit.called).toEqual(true)
  }

  @MainActor
  func testBadUserTypeIgnoresDanger() async {
    let store = self.featureStore()
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

  @MainActor
  func testBadUserTypeNoChoice() async {
    let store = self.featureStore()
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

  @MainActor
  func testBadUserTypeWithChoice() async {
    let store = self.featureStore()

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
    await store.receive(.delegate(.saveForResume(.at(step: .macosUserAccountType))))

    await store.send(.webview(.chooseDemoteAdminClicked)) {
      $0.userRemediationStep = .demote
    }
  }

  @MainActor
  func testSettingStepDoesntOpenWindow() async {
    let store = self.featureStore {
      $0.windowOpen = false
    }
    // there's a 4 minute timeout for failed sys-ext install
    // so the onboarding could be closed by the time that triggers
    // sending a .setStep into the system, which should NOT reopen
    await store.send(.setStep(.installSysExt_failed))
    store.assert {
      $0.windowOpen = false
    }
  }

  @MainActor
  func testSysExtInstallTimeoutDoesntPullBackToFailScreenIfPastThere() async {
    let store = self.featureStore { $0.step = .installSysExt_trick }
    store.deps.mainQueue = .immediate
    let timedOut = LockIsolated(false)
    store.deps.filterExtension.state = { .notInstalled }

    // this is janky, but allows me to simulate timeout AFTER they proceeded
    store.deps.filterExtension.installOverridingTimeout = { seconds in
      if !timedOut.value {
        await Task.yield()
        return await store.deps.filterExtension.installOverridingTimeout(seconds)
      }
      return .timedOutWaiting
    }

    // they click next from sys-ext "trick" screen, triggering install
    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .installSysExt_allow
    }

    // they click help i'm stuck, going to fail screen
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.installSysExt_failed))

    // they click to skip the install from the fail screen
    await store.send(.webview(.secondaryBtnClicked)) {
      $0.step = .locateMenuBarIcon
    }

    // and then, the install times out...
    timedOut.setValue(true)
    await Task.megaYield(count: 50)
    await store.skipReceivedActions()

    store.assert {
      $0.step = .locateMenuBarIcon // ...and they should NOT be brought back to fail
    }
  }

  @MainActor
  func testSysExtInstallTimeoutDoesGoToFailScreenIfNotPastStage() async {
    let store = self.featureStore { $0.step = .installSysExt_trick }
    store.deps.mainQueue = .immediate
    let timedOut = LockIsolated(false)
    store.deps.filterExtension.state = { .notInstalled }

    // this is janky, but allows me to simulate timeout AFTER they proceeded
    store.deps.filterExtension.installOverridingTimeout = { seconds in
      if !timedOut.value {
        await Task.yield()
        return await store.deps.filterExtension.installOverridingTimeout(seconds)
      }
      return .timedOutWaiting
    }

    // they click next from sys-ext "trick" screen, triggering install
    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .installSysExt_allow
    }

    // they click help i'm stuck, going to fail screen
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.installSysExt_failed))

    // they click "try again" from the fail screen
    await store.send(.webview(.primaryBtnClicked)) {
      $0.step = .installSysExt_explain
    }

    // and then, the install times out...
    timedOut.setValue(true)
    await Task.megaYield(count: 50)
    await store.skipReceivedActions()

    store.assert {
      $0.step = .installSysExt_failed // ...and they SHOULD be moved to fail
    }
  }

  @MainActor
  func testAllNonCurrentUsersConsideredExemptable() {
    var state = OnboardingFeature.State()
    state.users = [
      .init(id: 501, name: "Dad", isAdmin: true),
      .init(id: 502, name: "Mom", isAdmin: true),
      .init(id: 503, name: "liljimmy", isAdmin: false),
    ]
    state.currentUser = .init(id: 503, name: "liljimmy", isAdmin: false)
    expect(state.exemptableUsers).toEqual([
      .init(id: 501, name: "Dad", isAdmin: true),
      .init(id: 502, name: "Mom", isAdmin: true),
    ])
  }

  @MainActor
  func testSkipsFDAStepIfOsCatalina() async {
    let store = self.featureStore { $0.step = .allowNotifications_failed }
    store.deps.device.osVersion = { .init(major: 10, minor: 15, patch: 7) }
    store.deps.app.hasFullDiskAccess = { fatalError() }
    store.deps.monitoring.screenRecordingPermissionGranted = { false }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.allowScreenshots_required))
  }

  @MainActor
  func testResumingToCheckFDA_Success() async {
    let (store, _) = AppReducer.testStore()
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.app.hasFullDiskAccess = { true } // <-- all good!
    store.deps.storage.savePersistentState = saveState.fn
    store.deps.monitoring.screenRecordingPermissionGranted = { false }

    store.deps.storage.loadPersistentState = { .mock {
      $0.resumeOnboarding = .checkingFullDiskAccessPermission // <-- resume here
    }}

    await store.send(.application(.didFinishLaunching))
    await store.skipReceivedActions()

    store.assert {
      $0.onboarding.windowOpen = true
      $0.onboarding.step = .allowFullDiskAccess_success
    }

    await expect(saveState.calls).toEqual([.mock { $0.resumeOnboarding = nil }])

    await store.send(.onboarding(.webview(.primaryBtnClicked)))
    await store.receive(.onboarding(.setStep(.allowScreenshots_required)))
  }

  @MainActor
  func testResumingToCheckFDA_Failure() async {
    let (store, _) = AppReducer.testStore()
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.app.hasFullDiskAccess = { false } // <-- still no bueno!
    store.deps.storage.savePersistentState = saveState.fn

    store.deps.storage.loadPersistentState = { .mock {
      $0.resumeOnboarding = .checkingFullDiskAccessPermission // <-- resume here
    }}

    await store.send(.application(.didFinishLaunching))
    await store.skipReceivedActions()

    store.assert {
      $0.onboarding.windowOpen = true
      $0.onboarding.step = .allowFullDiskAccess_failed
    }

    // since the perms are still wrong, we need to save state to
    // resume again after another quit & restart
    await expect(saveState.calls).toEqual([
      .mock { $0.resumeOnboarding = nil }, // <-- the first, default clear save
      .mock { $0.resumeOnboarding = .checkingFullDiskAccessPermission },
    ])

    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.step = .allowFullDiskAccess_grantAndRestart
    }
  }

  @MainActor
  func testSkipsFDAIfAlreadyGranted() async {
    let store = self.featureStore { $0.step = .allowNotifications_grant }
    store.deps.device.notificationsSetting = { .alert }
    store.deps.app.hasFullDiskAccess = { true } // <-- already granted, skip
    store.deps.monitoring.screenRecordingPermissionGranted = { false }
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowScreenshots_required))
  }

  @MainActor
  func testParentSkipsFDAStep() async {
    let store = self.featureStore { $0.step = .allowFullDiskAccess_grantAndRestart }
    store.deps.monitoring.screenRecordingPermissionGranted = { false }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.allowScreenshots_required))
  }

  @MainActor
  func testSkipsFromFDAFailed() async {
    let store = self.featureStore { $0.step = .allowFullDiskAccess_failed }
    store.deps.monitoring.screenRecordingPermissionGranted = { false }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.allowScreenshots_required))
  }

  // helpers

  func featureStore(
    mutateState: @escaping (inout OnboardingFeature.State) -> Void = { _ in }
  ) -> TestStoreOf<OnboardingFeature.Reducer> {
    var state = OnboardingFeature.State()
    state.windowOpen = true
    mutateState(&state)
    let store = TestStore(initialState: state) {
      OnboardingFeature.Reducer()
    }
    store.exhaustivity = .off
    store.deps.app.installLocation = { .inApplicationsDir }
    store.deps.device.osVersion = { .sequoia }
    return store
  }
}
