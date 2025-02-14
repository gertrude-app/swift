import Combine
import ComposableArchitecture
import Core
import MacAppRoute
import TestSupport
import XCore
import XCTest
import XExpect

@testable import App

final class FullDiskAccessOnboardingTests: XCTestCase {
  @MainActor
  func testUpgradeFDAHappyPath_exhaustive() async {
    let (store, _) = AppReducer.testStore(exhaustive: true, mockDeps: false) {
      $0.appUpdates.installedVersion = "2.7.1"
    }
    setOnboardingAncillaryFDAMocks(store)
    let filterReplacedInvocations = LockIsolated(0)
    store.deps.filterExtension.replace = {
      filterReplacedInvocations.withValue { $0 += 1 }
      return .installedSuccessfully
    }

    let checkInResult = CheckIn_v2.Output.mock {
      $0.browsers = []
      $0.latestRelease = .init(semver: "2.7.1")
      $0.userData = .monitored
      $0.trustedTime = Date.reference.timeIntervalSince1970
    }
    store.deps.api.checkIn = { _ in checkInResult }

    let startLoggingKeystrokes = mock(always: ())
    store.deps.monitoring.startLoggingKeystrokes = startLoggingKeystrokes.fn

    let hasFullDiskAccess = mock(returning: [false, false, true])
    store.deps.app.hasFullDiskAccess = hasFullDiskAccess.fn

    var saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    let persisted = Persistent.State(
      appVersion: "2.5.0", // 👈 they were on 2.5.0
      appUpdateReleaseChannel: .stable,
      filterVersion: "2.5.0",
      user: .monitored,
      resumeOnboarding: nil
    )
    store.deps.storage.loadPersistentState = { persisted }

    await store.send(.application(.didFinishLaunching))

    await store.receive(.filter(.receivedState(.installedAndRunning))) {
      $0.filter.extension = .installedAndRunning
    }

    await store.receive(.loadedPersistentState(persisted)) {
      $0.history.userConnection = .established(welcomeDismissed: true)
      $0.user.data = persisted.user
      $0.filter.version = "2.5.0"
    }

    await store.receive(.startProtecting(user: .monitored))
    await store.receive(.networkConnectionChanged(connected: true))
    await store.receive(.websocket(.connectedSuccessfully))

    // we're "onboarding", but since it's an upgrade make sure we're monitoring
    await expect(startLoggingKeystrokes.calls.count).toEqual(1)

    await store.receive(.checkIn(result: .success(checkInResult), reason: .startProtecting)) {
      $0.appUpdates.latestVersion = checkInResult.latestRelease
    }

    await store
      .receive(.appUpdates(.delegate(.updateSucceeded(oldVersion: "2.5.0", newVersion: "2.7.1")))) {
        $0.filter.version = "2.7.1"
      }

    expect(filterReplacedInvocations.value).toEqual(1)

    await store.receive(.setTrustedTimestamp(.reference)) {
      $0.timestamp = .reference
    }

    await store.receive(.checkIn(result: .success(checkInResult), reason: .appUpdated))
    await store.receive(.user(.updated(previous: persisted.user)))

    await store
      .receive(.onboarding(.delegate(.openForUpgrade(step: .allowFullDiskAccess_grantAndRestart)))) {
        $0.onboarding.step = .allowFullDiskAccess_grantAndRestart
        $0.onboarding.windowOpen = true
        $0.onboarding.upgrade = true
      }

    // from update success aftermath
    await store.receive(.filter(.receivedState(.installedAndRunning)))
    await store.receive(.setTrustedTimestamp(.reference))
    await store.receive(.user(.updated(previous: persisted.user)))
    await expect(saveState.calls.count).toEqual(3)

    let openSysPrefs = spy(on: SystemPrefsLocation.self, returning: ())
    store.deps.device.openSystemPrefs = openSysPrefs.fn
    let stopRelaunchWatcher = mock(always: ())
    store.deps.app.stopRelaunchWatcher = stopRelaunchWatcher.fn

    // they click "Grant Permission" on the allow full disk access screen...
    await store.send(.onboarding(.webview(.primaryBtnClicked)))

    // ...we make a note to resume here after a quit/restart
    await store.receive(
      .onboarding(.delegate(.saveForResume(.checkingFullDiskAccessPermission(upgrade: true))))
    )

    // ...and we send them to the full disk access grant system prefs pane
    await expect(openSysPrefs.calls).toEqual([.security(.fullDiskAccess)])
    // ...and we stop the relaunch watcher so it doesn't interfere w/ os restarting
    await expect(stopRelaunchWatcher.calls.count).toEqual(1)

    // check that we persisted the onboarding resumption state
    await expect(saveState.calls.count).toEqual(4)
    await expect(saveState.calls[3].resumeOnboarding)
      .toEqual(.checkingFullDiskAccessPermission(upgrade: true))

    let finalPersist = await saveState.calls[3]

    // shutdown tries to flush keystrokes and stop relauncher
    store.deps.monitoring.takePendingKeystrokes = { nil }
    store.deps.monitoring.commitPendingKeystrokes = { _ in }
    await store.send(.application(.willTerminate))

    // recreate the store to simulate a restart
    let (resumeStore, _) = AppReducer.testStore(exhaustive: true, mockDeps: false) {
      $0.appUpdates.installedVersion = "2.7.1" // change default in test store if possible
    }
    setOnboardingAncillaryFDAMocks(resumeStore)
    resumeStore.deps.device.boottime = { nil }
    resumeStore.deps.app.hasFullDiskAccess = { true } // <-- now they have it
    resumeStore.deps.api.checkIn = { _ in checkInResult }
    resumeStore.deps.monitoring.stopLoggingKeystrokes = {}

    let preventScreenCaptureNag = mock(always: Result<Void, StringError>.success(()))
    resumeStore.deps.app.preventScreenCaptureNag = preventScreenCaptureNag.fn

    saveState = spy(on: Persistent.State.self, returning: ())
    resumeStore.deps.storage.savePersistentState = saveState.fn

    let startLoggingKeystrokes2 = mock(always: ())
    resumeStore.deps.monitoring.startLoggingKeystrokes = startLoggingKeystrokes2.fn

    let resuming = Persistent.State(
      appVersion: "2.7.1",
      appUpdateReleaseChannel: .stable,
      filterVersion: "2.7.1",
      user: .monitored,
      resumeOnboarding: .checkingFullDiskAccessPermission(upgrade: true)
    )
    resumeStore.deps.storage.loadPersistentState = { resuming }

    expect(resuming).toEqual(finalPersist) // verify integrity of resumption simulation

    await resumeStore.send(.application(.didFinishLaunching))

    await expect(preventScreenCaptureNag.calls.count).toEqual(1)

    await resumeStore.receive(.filter(.receivedState(.installedAndRunning))) {
      $0.filter.extension = .installedAndRunning
    }

    await resumeStore.receive(.loadedPersistentState(resuming)) {
      $0.history.userConnection = .established(welcomeDismissed: true)
      $0.user.data = resuming.user
      $0.filter.version = "2.7.1"
    }

    await resumeStore.receive(.startProtecting(user: .monitored))
    await resumeStore.receive(.networkConnectionChanged(connected: true))

    // here we should resume onboarding
    await resumeStore
      .receive(.onboarding(.resume(.checkingFullDiskAccessPermission(upgrade: true)))) {
        $0.onboarding.windowOpen = true
        $0.onboarding.upgrade = true
      }

    await resumeStore.receive(.websocket(.connectedSuccessfully))
    await resumeStore.receive(.onboarding(.setStep(.allowFullDiskAccess_success))) {
      $0.onboarding.step = .allowFullDiskAccess_success
    }

    await resumeStore.receive(.checkIn(result: .success(checkInResult), reason: .startProtecting)) {
      $0.appUpdates.latestVersion = checkInResult.latestRelease
    }

    await resumeStore.receive(.user(.updated(previous: resuming.user)))

    await expect(saveState.calls.count).toEqual(2)

    // ensure we've restarted the monitoring after the FDA resume
    // NB: this was broken in 2.7.0 and 2.7.1
    await expect(startLoggingKeystrokes2.calls.count).toEqual(1)

    // they click "Done" on the success screen...
    await resumeStore.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.windowOpen = false // ... so we close the window then b/c upgrade
      $0.onboarding.upgrade = false
    }

    await resumeStore.receive(.onboarding(.delegate(.saveForResume(nil))))

    await expect(saveState.calls.count).toEqual(3)
    await expect(saveState.calls[2].resumeOnboarding).toBeNil()

    resumeStore.deps.app.stopRelaunchWatcher = {}
    resumeStore.deps.monitoring.takePendingKeystrokes = { nil }
    resumeStore.deps.monitoring.commitPendingKeystrokes = { _ in }
    await resumeStore.send(.application(.willTerminate))
  }

  @MainActor
  func testSkipsFDAStepIfOsCatalina() async {
    let store = onboardingFeatureStore { $0.step = .allowNotifications_failed }
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
      $0.resumeOnboarding = .checkingFullDiskAccessPermission(upgrade: false) // <-- resume here
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
      $0.resumeOnboarding = .checkingFullDiskAccessPermission(upgrade: false) // <-- resume here
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
      .mock { $0.resumeOnboarding = .checkingFullDiskAccessPermission(upgrade: false) },
    ])

    await store.send(.onboarding(.webview(.primaryBtnClicked)))
    await store.receive(.onboarding(.setStep(.allowFullDiskAccess_grantAndRestart)))
  }

  @MainActor
  func testSkipsFDAIfAlreadyGranted() async {
    let store = onboardingFeatureStore { $0.step = .allowNotifications_grant }
    store.deps.device.notificationsSetting = { .alert }
    store.deps.app.hasFullDiskAccess = { true } // <-- already granted, skip
    store.deps.monitoring.screenRecordingPermissionGranted = { false }
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowScreenshots_required))
  }

  @MainActor
  func testParentSkipsFDAStep() async {
    let store = onboardingFeatureStore { $0.step = .allowFullDiskAccess_grantAndRestart }
    store.deps.monitoring.screenRecordingPermissionGranted = { false }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.allowScreenshots_required))
  }

  @MainActor
  func testSkipsFromFDAFailed() async {
    let store = onboardingFeatureStore { $0.step = .allowFullDiskAccess_failed }
    store.deps.monitoring.screenRecordingPermissionGranted = { false }
    await store.send(.webview(.secondaryBtnClicked))
    await store.receive(.setStep(.allowScreenshots_required))
  }

  @MainActor
  func testSecondaryFromUpgradeFDAStartClosesWindowWithNoSaveForResume() async {
    let (store, _) = AppReducer.testStore {
      $0.onboarding.step = .allowFullDiskAccess_grantAndRestart
      $0.onboarding.upgrade = true
    }

    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    // they elect to not give full disk access
    await store.send(.onboarding(.webview(.secondaryBtnClicked))) {
      $0.onboarding.windowOpen = false // so we close upgrade onboarding
    }

    await expect(saveState.calls.count).toEqual(0)
  }

  @MainActor
  func testPrimaryFromUpgradeFDAFailGoesBacktoGrant() async {
    let store = onboardingFeatureStore {
      $0.step = .allowFullDiskAccess_failed
      $0.upgrade = true
    }
    store.deps.app.hasFullDiskAccess = { false }
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowFullDiskAccess_grantAndRestart))
  }

  @MainActor
  func testPrimaryFDAFailGoesToSuccessIfTheyFixed() async {
    let store = onboardingFeatureStore {
      $0.step = .allowFullDiskAccess_failed
      $0.upgrade = false
    }
    store.deps.app.hasFullDiskAccess = { true } // <-- they fixed it before click
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowFullDiskAccess_success))
  }

  @MainActor
  func testPrimaryFromUpgradeFDAFailGoesToSuccessIfTheyFixed() async {
    let store = onboardingFeatureStore {
      $0.step = .allowFullDiskAccess_failed
      $0.upgrade = true
    }
    store.deps.app.hasFullDiskAccess = { true } // <-- they fixed it before click
    await store.send(.webview(.primaryBtnClicked))
    await store.receive(.setStep(.allowFullDiskAccess_success))
  }

  @MainActor
  func testSecondaryFromUpgradeRestartFDAFailClosesPreventingResume() async {
    let (store, _) = AppReducer.testStore {
      $0.onboarding.windowOpen = false
      $0.onboarding.upgrade = false
    }

    store.deps.app.hasFullDiskAccess = { false }
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    await store.send(.onboarding(.resume(.checkingFullDiskAccessPermission(upgrade: true)))) {
      $0.onboarding.windowOpen = true
      $0.onboarding.upgrade = true
    }

    // they end up on the failed screen
    await store.receive(.onboarding(.setStep(.allowFullDiskAccess_failed)))

    // and we record that we're going to resume here, assuming they try again
    await expect(saveState.calls.count).toEqual(1)
    await expect(saveState.calls[0].resumeOnboarding)
      .toEqual(.checkingFullDiskAccessPermission(upgrade: true))

    // ... but instead they quit by clicking the secondary
    await store.send(.onboarding(.webview(.secondaryBtnClicked))) {
      $0.onboarding.windowOpen = false // so we close upgrade onboarding
    }

    // and won't resume
    await expect(saveState.calls.count).toEqual(2)
    await expect(saveState.calls[1].resumeOnboarding).toBeNil()
  }

  @MainActor
  func testUpgradeHappyPathSimulatingRestart() async {
    let (store, _) = AppReducer.testStore {
      $0.onboarding.windowOpen = false
      $0.onboarding.upgrade = false
    }
    store.deps.app.hasFullDiskAccess = { true }
    await store.send(.onboarding(.resume(.checkingFullDiskAccessPermission(upgrade: true)))) {
      $0.onboarding.windowOpen = true
      $0.onboarding.upgrade = true // <-- we know we're still in upgrade mode...
    }
    await store.receive(.onboarding(.setStep(.allowFullDiskAccess_success))) {
      $0.onboarding.step = .allowFullDiskAccess_success
    }
    await store.send(.onboarding(.webview(.primaryBtnClicked))) {
      $0.onboarding.windowOpen = false // ... so we close the window then b/c upgrade
      $0.onboarding.upgrade = false
    }
  }
}

func setOnboardingAncillaryFDAMocks(_ store: TestStoreOf<AppReducer>) {
  store.useMainSerialExecutor = true
  store.deps.filterExtension.setup = { .installedAndRunning }
  store.deps.filterExtension.state = { .installedAndRunning }
  store.deps.filterExtension.stateChanges = { Empty().eraseToAnyPublisher() }
  store.deps.date = .constant(.reference)
  store.deps.api.setAccountActive = { _ in }
  store.deps.api.setUserToken = { _ in }
  store.deps.api.logSecurityEvent = { _, _ in }
  store.deps.backgroundQueue = DispatchQueue.test.eraseToAnyScheduler()
  store.deps.mainQueue = .immediate
  store.deps.filterXpc = .mock
  store.deps.device = .mock
  store.deps.device.boottime = { .reference }
  store.deps.app.installedVersion = { "2.7.1" }
  store.deps.app.isLaunchAtLoginEnabled = { true }
  store.deps.app.startRelaunchWatcher = {}
  store.deps.monitoring.keystrokeRecordingPermissionGranted = { true }
  store.deps.monitoring.screenRecordingPermissionGranted = { true }
  store.deps.websocket.receive = { Empty().eraseToAnyPublisher() }
  store.deps.websocket = .mock
}

extension TrustedTimestamp {
  static let reference = TrustedTimestamp(
    network: .reference,
    system: .reference,
    boottime: .reference
  )
}
