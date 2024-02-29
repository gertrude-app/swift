import Combine
import ComposableArchitecture
import Core
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App
@testable import Gertie

@MainActor final class AppReducerTests: XCTestCase {
  func testDidFinishLaunching_Exhaustive() async {
    let (store, _) = AppReducer.testStore(exhaustive: true)

    let extSetup = mock(always: FilterExtensionState.installedButNotRunning)
    store.deps.filterExtension.setup = extSetup.fn
    let setUserToken = spy(on: UUID.self, returning: ())
    store.deps.api.setUserToken = setUserToken.fn
    let filterStateSubject = PassthroughSubject<FilterExtensionState, Never>()
    store.deps.filterExtension.stateChanges = { filterStateSubject.eraseToAnyPublisher() }
    store.deps.storage.loadPersistentState = { .mock }
    store.deps.app.isLaunchAtLoginEnabled = { false }
    let enableLaunchAtLogin = mock(always: ())
    store.deps.app.enableLaunchAtLogin = enableLaunchAtLogin.fn
    let startRelaunchWatcher = mock(always: ())
    store.deps.app.startRelaunchWatcher = startRelaunchWatcher.fn

    await store.send(.application(.didFinishLaunching))

    await store.receive(.loadedPersistentState(.mock)) {
      $0.user = .init(data: .mock)
      $0.history.userConnection = .established(welcomeDismissed: true)
    }

    await expect(extSetup.invocations).toEqual(1)

    await store.receive(.filter(.receivedState(.installedButNotRunning))) {
      $0.filter.extension = .installedButNotRunning
    }

    await store.receive(.startProtecting(user: .mock))
    await store.receive(.websocket(.connectedSuccessfully))

    await expect(setUserToken.invocations).toEqual([UserData.mock.token])
    await expect(enableLaunchAtLogin.invocations).toEqual(1)
    await expect(startRelaunchWatcher.invocations).toEqual(1)

    let prevUser = store.state.user.data

    await store.receive(.checkIn(result: .success(.mock), reason: .startProtecting)) {
      $0.appUpdates.latestVersion = .init(semver: "2.0.4")
      $0.user.data?.screenshotsEnabled = true
      $0.user.data?.keyloggingEnabled = true
      $0.user.data?.screenshotFrequency = 333
      $0.user.data?.screenshotSize = 555
      $0.browsers = CheckIn.Output.mock.browsers
    }

    await store.receive(.user(.updated(previous: prevUser)))

    filterStateSubject.send(.notInstalled)
    await store.receive(.filter(.receivedState(.notInstalled))) {
      $0.filter.extension = .notInstalled
    }

    filterStateSubject.send(.installedButNotRunning)
    await store.receive(.filter(.receivedState(.installedButNotRunning))) {
      $0.filter.extension = .installedButNotRunning
    }

    filterStateSubject.send(completion: .finished)
    await store.send(.application(.willTerminate)) // cancel heartbeat
  }

  func testOnboardingDelegateSaveStepPersists() async {
    let (store, _) = AppReducer.testStore()
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn

    await store.send(.onboarding(.delegate(.saveForResume(.at(step: .macosUserAccountType)))))
    await expect(saveState.invocations.value[0].resumeOnboarding)
      .toEqual(.at(step: .macosUserAccountType))
  }

  func testDidFinishLaunching_EstablishesConnectionIfFilterOn() async {
    let (store, bgQueue) = AppReducer.testStore()
    store.deps.storage.loadPersistentState = { nil }
    store.deps.filterExtension.setup = { .installedAndRunning }

    let connectionEstablished = ActorIsolated(false)
    store.deps.filterXpc.establishConnection = {
      await connectionEstablished.setValue(true)
      return .success(())
    }

    await store.send(.application(.didFinishLaunching))
    await bgQueue.advance(by: .milliseconds(5))
    await Task.repeatYield()

    await expect(connectionEstablished).toEqual(true)
  }

  func testDidFinishLaunching_NoPersistentUser() async {
    let (store, _) = AppReducer.testStore()
    store.deps.storage.loadPersistentState = { nil }

    await store.send(.application(.didFinishLaunching))
    await store.receive(.loadedPersistentState(nil))
  }

  func testHeartbeatClearSuspensionFallback() async {
    let now = Date()
    let (store, scheduler) = AppReducer.testStore {
      $0.filter.currentSuspensionExpiration = now.advanced(by: 60 * 3)
    }

    let time = ControllingNow(starting: now, with: scheduler)
    store.deps.date = time.generator

    await store.send(.application(.didFinishLaunching))

    await time.advance(seconds: 60)
    await store.receive(.heartbeat(.everyMinute))

    await time.advance(seconds: 60)
    await store.receive(.heartbeat(.everyMinute))
    expect(store.state.filter.currentSuspensionExpiration).not.toBeNil()

    await time.advance(seconds: 60)
    await store.receive(.heartbeat(.everyMinute)) {
      $0.filter.currentSuspensionExpiration = nil
    }
  }
}

// helpers

extension AppReducer {
  static func testStore<R: ReducerOf<AppReducer>>(
    exhaustive: Bool = false,
    mockDeps: Bool = true,
    reducer: R = AppReducer(),
    mutateState: @escaping (inout State) -> Void = { _ in }
  ) -> (TestStoreOf<AppReducer>, TestSchedulerOf<DispatchQueue>) {
    var state = State(appVersion: "1.0.0")
    mutateState(&state)
    let store = TestStore(initialState: state, reducer: { reducer })
    store.useMainSerialExecutor = true
    store.exhaustivity = exhaustive ? .on : .off
    let scheduler = DispatchQueue.test
    if mockDeps {
      store.deps.date = .constant(Date(timeIntervalSince1970: 0))
      store.deps.backgroundQueue = scheduler.eraseToAnyScheduler()
      store.deps.mainQueue = .immediate
      store.deps.monitoring = .mock
      store.deps.storage = .mock
      store.deps.storage.loadPersistentState = { .mock }
      store.deps.app = .mock
      store.deps.api = .mock
      store.deps.device = .mock
      store.deps.api.checkIn = { _ in .mock }
      store.deps.filterExtension = .mock
      store.deps.filterXpc = .mock
      store.deps.websocket = .mock
    }
    return (store, scheduler)
  }
}
