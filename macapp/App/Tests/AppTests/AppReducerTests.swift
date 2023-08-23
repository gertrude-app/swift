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
    let (store, bgQueue) = AppReducer.testStore(exhaustive: true)

    let filterSetupSpy = ActorIsolated(false)
    store.deps.filterExtension.setup = {
      await filterSetupSpy.setValue(true)
      return .installedButNotRunning
    }

    let tokenSetSpy = ActorIsolated<UUID?>(nil)
    store.deps.api.setUserToken = { await tokenSetSpy.setValue($0) }

    let filterStateSubject = PassthroughSubject<FilterExtensionState, Never>()
    store.deps.filterExtension.stateChanges = { filterStateSubject.eraseToAnyPublisher() }
    store.deps.storage.loadPersistentState = { .mock }

    await store.send(.application(.didFinishLaunching))

    await store.receive(.loadedPersistentState(.mock)) {
      $0.user = .init(data: .mock)
      $0.history.userConnection = .established(welcomeDismissed: true)
    }

    await store.receive(.websocket(.connectedSuccessfully))

    await expect(tokenSetSpy).toEqual(UserData.mock.token)

    await bgQueue.advance(by: .milliseconds(5))
    await expect(filterSetupSpy).toEqual(true)

    await store.receive(.filter(.receivedState(.installedButNotRunning))) {
      $0.filter.extension = .installedButNotRunning
    }

    let prevUser = store.state.user.data

    await bgQueue.advance(by: .milliseconds(5))
    await store.receive(.checkIn(result: .success(.mock), reason: .appLaunched)) {
      $0.appUpdates.latestVersion = .init(semver: "2.0.4")
      $0.user.data?.screenshotsEnabled = true
      $0.user.data?.keyloggingEnabled = true
      $0.user.data?.screenshotFrequency = 333
      $0.user.data?.screenshotSize = 555
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
    reducer: R = AppReducer(),
    mutateState: @escaping (inout State) -> Void = { _ in }
  ) -> (TestStoreOf<AppReducer>, TestSchedulerOf<DispatchQueue>) {
    var state = State()
    mutateState(&state)
    let store = TestStore(initialState: state, reducer: { reducer })
    store.exhaustivity = exhaustive ? .on : .off
    let scheduler = DispatchQueue.test
    store.deps.date = .constant(Date(timeIntervalSince1970: 0))
    store.deps.backgroundQueue = scheduler.eraseToAnyScheduler()
    store.deps.mainQueue = .immediate
    store.deps.storage.loadPersistentState = { .mock }
    store.deps.api.checkIn = { _ in .mock }
    store.deps.filterExtension.setup = { .installedAndRunning }
    return (store, scheduler)
  }
}
